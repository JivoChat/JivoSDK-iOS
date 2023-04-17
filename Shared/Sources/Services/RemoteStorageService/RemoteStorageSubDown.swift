//
//  RemoteStorageSubMediaDown.swift
//  App
//
//  Created by Stan Potemkin on 06.11.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation

import JMTimelineKit
import JMCodingKit
import Gzip
import SwiftMime

class RemoteStorageSubDown: IRemoteStorageServiceDown {
    let cacheDriver: ICacheDriver
    let cachingDirectory: String

    internal let resourceQueue = OperationQueue()
    internal let resourceMutex = NSLock()
    
    private var enqueuedResourceCallbacks: [CachedParams: [(RemoteStorageFileResource) -> Void]] // Кажется, что лучше было бы сделать один dictionary-кэш, в котором отслеживались бы все состояния выполнения запроса на получение медиа: и состояние "добавлено в очередь", и состояние "загружено". Состояния (значения dictionary) могли бы быть представлены в виде енума.
    
    init(cacheDriver: ICacheDriver, cachingDirectory: String) {
        self.cacheDriver = cacheDriver
        self.cachingDirectory = cachingDirectory
        
        resourceQueue.qualityOfService = .userInteractive
        resourceQueue.maxConcurrentOperationCount = 1
        
        enqueuedResourceCallbacks = Dictionary()
    }
    
    func retrieveURL(originURL: URL, quality: RemoteStorageQuality, on completionQueue: DispatchQueue, completion: @escaping (URL?) -> Void) {
        preconditionFailure()
    }
    
    func retrieveCachedURL(originURL: URL, quality: RemoteStorageQuality) -> URL? {
        preconditionFailure()
    }
    
    func retrieveFile(originURL: URL, quality: RemoteStorageQuality, caching: RemoteStorageCaching, on callbackQueue: DispatchQueue, callback: @escaping (RemoteStorageFileResource) -> Void) {
        resourceQueue.addOperation { [unowned self] in
            let params = CachedParams(url: originURL, quality: quality)
            
            if caching == .enabled, let wrapper = globalResourceCache.object(forKey: params.storableKey as NSString) {
                return callbackQueue.async {
                    callback(wrapper.resource)
                }
            }
            else if let callbacks = enqueuedResourceCallbacks[params] {
                enqueuedResourceCallbacks[params] = callbacks + [callback]
                return callbackQueue.async {
                    callback(.waiting)
                }
            }
            else {
                enqueuedResourceCallbacks[params] = [callback]
                callbackQueue.async {
                    callback(.waiting)
                }
            }
            
            if let wrapper = globalResourceCache.object(forKey: params.storableKey as NSString) {
                return callbackQueue.async {
                    callback(wrapper.resource)
                }
            }
            
            retrieveURL(originURL: originURL, quality: quality, on: callbackQueue) { [unowned self] signedURL in
                guard let signedURL = signedURL else {
                    return informOut(
                        params: params,
                        resource: .failure(error: .unableToSignURL),
                        on: callbackQueue)
                }
                
                resourceQueue.addOperation { [unowned self] in
                    retrieveResource(
                        params: params,
                        originURL: originURL,
                        signedURL: signedURL,
                        on: callbackQueue,
                        completion: callback)
                }
            }
        }
    }
    
    func retrieveMeta(originURL: URL, caching: RemoteStorageCaching, on completionQueue: DispatchQueue, completion: @escaping (Result<RemoteStorageFileInfo, RemoteStorageFileInfoError>) -> Void) {
        preconditionFailure()
    }
    
    internal var filePolicy: RemoteStorageFilePurpose {
        return .origin
    }
    
    private func retrieveResource(params: CachedParams, originURL: URL, signedURL: URL, on completionQueue: DispatchQueue, completion: @escaping (RemoteStorageFileResource) -> Void) {
        let localBinItem = CacheDriverItem(
            directoryName: cachingDirectory,
            hashing: originURL.absoluteString,
            ext: "bin"
        )
        
        let localMimeItem = CacheDriverItem(
            directoryName: cachingDirectory,
            hashing: originURL.absoluteString,
            ext: "mime"
        )
        
        if let localBinURL = cacheDriver.existingUrl(item: localBinItem), let mimeBin = cacheDriver.readData(item: localMimeItem) {
            let mime = String(data: mimeBin, encoding: .utf8) ?? String()
            handleResource(
                params: params,
                originURL: originURL,
                localURL: localBinURL,
                mime: mime,
                on: completionQueue)
        }
        else {
            URLSession.shared.downloadTask(with: signedURL) { [unowned self] tmpURL, response, error in
                guard
                    let tmpURL = tmpURL,
                    let localURL = cacheDriver.replace(item: localBinItem, sourceURL: tmpURL),
                    let response = response as? HTTPURLResponse, response.statusCode < 400
                else {
                    informOut(params: params, resource: .failure(error: .notFound), on: completionQueue)
                    return
                }
                
                let mime = response.mimeType ?? String()
                let mimeBin = mime.data(using: .utf8) ?? Data()
                cacheDriver.write(item: localMimeItem, data: mimeBin)
                
                handleResource(
                    params: params,
                    originURL: originURL,
                    localURL: localURL,
                    mime: mime,
                    on: completionQueue)
            }
            .resume()
        }
        
//        let urlRequest = URLRequest(url: signedURL)
//        let urlSession = URLSession.shared
//        let dataTask = urlSession.dataTask(with: urlRequest) { [weak self] data, response, error in
//            guard let `self` = self else { return }
//
//            self.resourceQueue.addOperation {
//                guard let httpURLResponse = response as? HTTPURLResponse else {
//                    return self._fireResource(params: params, resource: .failure(.unknown(statusCode: nil, error: error)), on: completionQueue)
//                }
//
//                let statusCode = httpURLResponse.statusCode
//                guard (200..<300).contains(statusCode), error == nil else {
//                    switch statusCode {
//                    case 401:
//                        return self._fireResource(params: params, resource: .failure(.unauthorized), on: completionQueue)
//                    case 403:
//                        return self._fireResource(params: params, resource: .failure(.forbidden), on: completionQueue)
//                    case 404:
//                        return self._fireResource(params: params, resource: .failure(.notFound), on: completionQueue)
//                    default:
//                        return self._fireResource(params: params, resource: .failure(.unknown(statusCode: statusCode, error: error)), on: completionQueue)
//                    }
//                }
//
//                guard let data = data else {
//                    return self._fireResource(params: params, resource: .failure(.notFound), on: completionQueue)
//                }
//
//                if not(data.isGzipped) {
//                    let resource = JMTimelineResource.raw(data)
//                    globalResourceCache.setObject(ResourceWrapper(resource: resource), forKey: params.storableKey as NSString)
//                    self._fireResource(params: params, resource: .value(resource), on: completionQueue)
//                }
//                else {
//                    guard let payload = try? data.gunzipped() else {
//                        let resource = JMTimelineResource.raw(data)
//                        globalResourceCache.setObject(ResourceWrapper(resource: resource), forKey: params.storableKey as NSString)
//                        return self._fireResource(params: params, resource: .value(resource), on: completionQueue)
//                    }
//
//                    if let animation = try? JSONDecoder().decode(Animation.self, from: payload) {
//                        let resource = JMTimelineResource.lottie(animation)
//                        globalResourceCache.setObject(ResourceWrapper(resource: resource), forKey: params.storableKey as NSString)
//                        self._fireResource(params: params, resource: .value(resource), on: completionQueue)
//                    }
//                    else {
//                        let resource = JMTimelineResource.raw(data)
//                        globalResourceCache.setObject(ResourceWrapper(resource: resource), forKey: params.storableKey as NSString)
//                        self._fireResource(params: params, resource: .value(resource), on: completionQueue)
//                    }
//                }
//            }
//        }
//
//        dataTask.resume()
    }
    
    private func handleResource(params: CachedParams, originURL: URL, localURL: URL, mime: String, on completionQueue: DispatchQueue) {
        if mime.hasPrefix("image/") {
            let data = (try? Data(contentsOf: localURL)) ?? Data()
            let image = UIImage(data: data) ?? UIImage()
            
            linkAndInform(
                params: params,
                mime: mime,
                originURL: originURL,
                localURL: localURL,
                kind: .image(image),
                ext: SwiftMime.ext(mime) ?? "jpeg",
                completionQueue: completionQueue
            )
        }
        else if mime.hasPrefix("video/") {
            linkAndInform(
                params: params,
                mime: mime,
                originURL: originURL,
                localURL: localURL,
                kind: .video,
                ext: SwiftMime.ext(mime) ?? "mp4",
                completionQueue: completionQueue
            )
        }
        else if mime.hasPrefix("audio/preview") {
            linkAndInform(
                params: params,
                mime: mime,
                originURL: originURL,
                localURL: localURL,
                kind: .binary,
                ext: "hex",
                completionQueue: completionQueue
            )
        }
    }
    
    private func linkAndInform(params: CachedParams, mime: String, originURL: URL, localURL: URL, kind: RemoteStorageFileKind, ext: String, completionQueue: DispatchQueue) {
        let aliasURL = localURL.deletingPathExtension().appendingPathExtension(ext)
        cacheDriver.link(aliasUrl: aliasURL, realUrl: localURL)
        
        let meta = RemoteStorageFileResource.ValueMeta(
            mime: mime,
            originUrl: originURL,
            localUrl: aliasURL,
            purpose: filePolicy
        )
        
        let resource = RemoteStorageFileResource.value(meta: meta, kind: kind)
        globalResourceCache.setObject(ResourceWrapper(resource: resource), forKey: params.storableKey as NSString)
        
        informOut(params: params, resource: resource, on: completionQueue)
    }
    
    private func informOut(params: CachedParams, resource: RemoteStorageFileResource, on callbackQueue: DispatchQueue) {
        let callbacks = enqueuedResourceCallbacks.removeValue(forKey: params) ?? Array()
        callbackQueue.async {
            for callback in callbacks {
                callback(resource)
            }
        }
    }
}

fileprivate let globalResourceCache = NSCache<NSString, ResourceWrapper>()
@objc fileprivate final class ResourceWrapper: NSObject {
    var resource = RemoteStorageFileResource.waiting
    init(resource: RemoteStorageFileResource) { self.resource = resource }
}

fileprivate struct CachedParams: Hashable {
    let url: URL
    let quality: RemoteStorageQuality
    
    var storableKey: String {
        return "\(url):\(quality)"
    }
}
