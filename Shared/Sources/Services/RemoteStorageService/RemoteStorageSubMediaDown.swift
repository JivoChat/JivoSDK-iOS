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

enum RemoteStorageFileMetaRequestState {
    case enqueuedWithCallbacks([(Result<RemoteStorageFileInfo, RemoteStorageFileInfoError>) -> Void])
    case performedWithResult(Result<RemoteStorageFileInfo, RemoteStorageFileInfoError>)
}

final class RemoteStorageSubMediaDown: RemoteStorageSubDown {
    private let networking: INetworking
    private let endpointAccessor: IKeychainAccessor
    private let tokenProvider: () -> String?
    private let urlBuilder: NetworkingUrlBuilder
    
    private let jsonCoder = JsonCoder()
    private var resolvedSigns: [CachedParams: (url: URL, tillTime: Date)]
    private var enqueuedSignedURLCallbacks: [CachedParams: [(URL?) -> Void]]
    private var fileMetaRequestStates: [URL: RemoteStorageFileMetaRequestState]
    
    init(networking: INetworking, endpointAccessor: IKeychainAccessor, cacheDriver: ICacheDriver, cachingDirectory: String, tokenProvider: @escaping () -> String?, urlBuilder: @escaping NetworkingUrlBuilder) {
        self.networking = networking
        self.endpointAccessor = endpointAccessor
        self.tokenProvider = tokenProvider
        self.urlBuilder = urlBuilder
        
        resolvedSigns = Dictionary()
        enqueuedSignedURLCallbacks = Dictionary()
        fileMetaRequestStates = Dictionary()

        super.init(cacheDriver: cacheDriver, cachingDirectory: cachingDirectory)
    }
    
    override func retrieveURL(originURL: URL, quality: RemoteStorageQuality, on completionQueue: DispatchQueue, completion: @escaping (URL?) -> Void) {
        resourceQueue.addOperation { [unowned self] in
            let params = CachedParams(url: originURL, quality: quality)
            requestForSignedURL(params: params, on: completionQueue) { signedURL in
                completion(signedURL)
            }
        }
    }
    
    override func retrieveCachedURL(originURL: URL, quality: RemoteStorageQuality) -> URL? {
        let params = CachedParams(url: originURL, quality: quality)
        resourceMutex.lock()
        let url = resolvedSigns[params]?.url
        resourceMutex.unlock()
        return url
    }
    
    override func retrieveMeta(originURL: URL, caching: RemoteStorageCaching, on completionQueue: DispatchQueue, completion: @escaping (Result<RemoteStorageFileInfo, RemoteStorageFileInfoError>) -> Void) {
        resourceQueue.addOperation { [weak self] in
            if let sameURLRequestState = self?.fileMetaRequestStates[originURL] {
                if case let .performedWithResult(result) = sameURLRequestState, caching == .enabled {
                    return completionQueue.async {
                        completion(result)
                    }
                }
                else if case .performedWithResult = sameURLRequestState, caching == .disabled {
                    self?.fileMetaRequestStates[originURL] = .enqueuedWithCallbacks([completion])
                }
                else if case let .enqueuedWithCallbacks(callbacks) = sameURLRequestState {
                    self?.fileMetaRequestStates[originURL] = .enqueuedWithCallbacks(callbacks + [completion])
                    return
                }
            } else {
                self?.fileMetaRequestStates[originURL] = .enqueuedWithCallbacks([completion])
            }
            
            self?.retrieveURL(originURL: originURL, quality: .original, on: completionQueue) { signedURL in
                if let signedURL = signedURL {
                    self?.performMetaRequest(url: signedURL) { result in
                        self?.resourceQueue.addOperation {
                            self?.informAboutFileMeta(url: originURL, result: result, on: completionQueue)
                        }
                    }
                }
                else {
                    self?.informAboutFileMeta(url: originURL, result: .failure(.unauthorized), on: completionQueue)
                }
            }
        }
    }
    
    override var filePolicy: RemoteStorageFilePurpose {
        return .preview
    }
    
    private func requestForSignedURL(params: CachedParams, on completionQueue: DispatchQueue, completion: @escaping (URL?) -> Void) {
        resourceMutex.lock()
        let cachedItem = resolvedSigns[params]
        resourceMutex.unlock()
        
        if let item = cachedItem, Date() < item.tillTime {
            return completionQueue.async {
                completion(item.url)
            }
        }
        else if let callbacks = enqueuedSignedURLCallbacks[params] {
            enqueuedSignedURLCallbacks[params] = callbacks + [completion]
            return
        }
        else {
            enqueuedSignedURLCallbacks[params] = [completion] // completion-блок в этом методе не вызывается напрямую, а лишь сохраняется в enqueuedSignedURLCallbacks, чтобы потом быть вызванным через _fireSignedURL
        }
        
        guard
            let sub = endpointAccessor.string,
            let url = urlBuilder(networking.baseURL(module: "api"), sub, .replace("auth"), "/api/1.0/auth/media/app/sign/get"),
            var signComponents = URLComponents(string: url.absoluteString)
        else {
            informAboutSignedURL(params: params, signedURL: params.url, on: completionQueue)
            return
        }
        
        signComponents.queryItems = [
            URLQueryItem(name: "file", value: params.url.absoluteString)
        ]
        
        guard
            let signURL = signComponents.url,
            let token = tokenProvider() // Кажется, что проверка существования токена должна осуществляться вовне сервиса
        else {
            informAboutSignedURL(params: params, signedURL: params.url, on: completionQueue)
            return
        }
        
        var signRequest = URLRequest(url: signURL)
        signRequest.setValue(token, forHTTPHeaderField: "Authorization")
        
        URLSession.shared
            .dataTask(with: signRequest) { [unowned self] data, response, error in // Не понял, почему мы используем unowned self вместо weak self
                guard let data = data else {
                    return resourceQueue.addOperation { [unowned self] in
                        informAboutSignedURL(params: params, signedURL: nil, on: completionQueue)
                    }
                }
                
                guard let json = jsonCoder.decode(binary: data, encoding: .utf8) else {
                    return resourceQueue.addOperation { [unowned self] in
                        informAboutSignedURL(params: params, signedURL: nil, on: completionQueue)
                    }
                }
                
                guard let sign = json["sign"].string else {
                    return resourceQueue.addOperation { [unowned self] in
                        informAboutSignedURL(params: params, signedURL: nil, on: completionQueue)
                    }
                }
                
                guard let timestamp = json["ts"].int else {
                    return resourceQueue.addOperation { [unowned self] in
                        informAboutSignedURL(params: params, signedURL: nil, on: completionQueue)
                    }
                }
                
                guard var components = URLComponents(string: params.url.absoluteString) else {
                    return resourceQueue.addOperation { [unowned self] in
                        informAboutSignedURL(params: params, signedURL: nil, on: completionQueue)
                    }
                }
                
                components.queryItems = {
                    let basicItems = [
                        URLQueryItem(name: "sign", value: sign),
                        URLQueryItem(name: "ts", value: String(describing: timestamp)),
                    ]
                    
                    switch params.quality {
                    case .preview(let width):
                        let thumbItem = URLQueryItem(name: "thumb", value: nil)
                        let widthItem = URLQueryItem(name: "width", value: String(describing: Int(width)))
                        return basicItems + [thumbItem, widthItem]
                    case .original:
                        return basicItems
                    }
                }()
                
                if let signedURL = components.url {
                    let tillTime = Date(timeIntervalSince1970: Double(timestamp))
                    self.resourceMutex.lock()
                    self.resolvedSigns[params] = (signedURL, tillTime)
                    self.resourceMutex.unlock()
                }
                
                resourceQueue.addOperation { [unowned self] in
                    informAboutSignedURL(params: params, signedURL: components.url, on: completionQueue)
                }
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
    
    private func performMetaRequest(url: URL, completion: @escaping (Result<RemoteStorageFileInfo, RemoteStorageFileInfoError>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = RestRequestMethod.head.rawValue
        
        let urlSession = URLSession.shared
        let dataTask = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let httpURLResponse = response as? HTTPURLResponse else {
                return completion(.failure(.unknown(statusCode: nil, error: error)))
            }
            
            let statusCode = httpURLResponse.statusCode
            guard (200..<300).contains(statusCode) else {
                switch statusCode {
                case 401: return completion(.failure(.unauthorized))
                case 404: return completion(.failure(.notFound))
                default: return completion(.failure(.unknown(statusCode: statusCode, error: error)))
                }
            }
            
            guard let fileMeta = self?.decodeFileMetaRequest(response: httpURLResponse) else {
                return completion(.failure(.unableToDecode))
            }
            
            completion(.success(fileMeta))
        }
        dataTask.resume()
    }
    
    private func decodeFileMetaRequest(response: HTTPURLResponse) -> RemoteStorageFileInfo {
        let headers = stringHeaders(for: response.allHeaderFields)
        let fileNameSource = headers["Content-Disposition"] ?? String()
        
        let fileName: String
        do {
            let regex = try NSRegularExpression(
                pattern: "filename(?:\\*=[a-zA-Z0-9_-]+\\'[\\w_-]*?\\'|=)([\"\']?)(.+)(\\1)",
                options: [.caseInsensitive]
            )
            
            if let match = regex.firstMatch(in: fileNameSource, options: [], range: NSRange(location: 0, length: fileNameSource.utf16.count)) {
                if let range = Range(match.range(at: 2), in: fileNameSource) {
                    fileName = String(fileNameSource[range])
                }
                else {
                    fileName = fileNameSource
                }
            }
            else {
                fileName = fileNameSource
            }
        }
        catch {
            fileName = fileNameSource
        }
        
        return RemoteStorageFileInfo(
            name: fileName.jv_unescape() ?? fileName
        )
    }
    
    private func stringHeaders(for anyTypeHeaders: [AnyHashable: Any]) -> [String: String] {
        let convertedHeaders = Dictionary<String, String>(
            uniqueKeysWithValues: anyTypeHeaders
                .compactMap { header in
                    guard
                        let key = header.0 as? String,
                        let value = header.1 as? String
                    else { return nil }
                    return (key: key, value: value)
                }
        )
        return convertedHeaders
    }
    
    private func informAboutSignedURL(params: CachedParams, signedURL: URL?, on callbackQueue: DispatchQueue) {
        let callbacks = enqueuedSignedURLCallbacks.removeValue(forKey: params) ?? Array()
        callbackQueue.async {
            for callback in callbacks {
                callback(signedURL)
            }
        }
    }
    
    private func informAboutFileMeta(url: URL, result: Result<RemoteStorageFileInfo, RemoteStorageFileInfoError>, on callbackQueue: DispatchQueue) {
        guard case let .enqueuedWithCallbacks(callbacks) = fileMetaRequestStates[url] else { return }
        fileMetaRequestStates[url] = .performedWithResult(result)
        
        callbackQueue.async {
            callbacks.forEach { callback in
                callback(result)
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
