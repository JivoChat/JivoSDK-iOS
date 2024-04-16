//
//  RemoteStorageSubFilesDown.swift
//  App
//
//  Created by Stan Potemkin on 12.11.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation
import JMTimelineKit
import JMCodingKit
import Gzip

final class RemoteStorageSubFilesDown: RemoteStorageSubDown {
    private let tokenProvider: () -> String?
    
    private let jsonCoder = JsonCoder()
    
    init(cacheDriver: ICacheDriver, cachingDirectory: String, tokenProvider: @escaping () -> String?) {
        self.tokenProvider = tokenProvider
        
        super.init(cacheDriver: cacheDriver, cachingDirectory: cachingDirectory)
    }
    
    override func retrieveURL(endpoint: String?, originURL: URL, quality: RemoteStorageQuality, on completionQueue: DispatchQueue, completion: @escaping (URL?) -> Void) {
        completionQueue.async {
            completion(originURL)
        }
    }
    
    override func retrieveCachedURL(originURL: URL, quality: RemoteStorageQuality) -> URL? {
        return originURL
    }
    
    override func retrieveMeta(endpoint: String?, originURL: URL, caching: RemoteStorageCaching, on completionQueue: DispatchQueue, completion: @escaping (Result<RemoteStorageFileInfo, RemoteStorageFileInfoError>) -> Void) {
        return completionQueue.async {
            completion(.failure(.notFromCloudStorage))
        }
    }
    
//        guard let data = try? Data(contentsOf: signedURL) else {
//            return _fireResource(params: params, resource: .value(.failure()), on: completionQueue)
//        }
        
//        if not(data.isGzipped) {
//            let resource = JMTimelineResource.raw(data)
//            globalResourceCache.setObject(ResourceWrapper(resource: resource), forKey: params.storableKey as NSString)
//            _fireResource(params: params, resource: .value(resource), on: completionQueue)
//        }
//        else {
//            guard let payload = try? data.gunzipped() else {
//                let resource = JMTimelineResource.raw(data)
//                globalResourceCache.setObject(ResourceWrapper(resource: resource), forKey: params.storableKey as NSString)
//                return _fireResource(params: params, resource: .value(resource), on: completionQueue)
//            }
//
//            if let animation = try? JSONDecoder().decode(Animation.self, from: payload) {
//                let resource = JMTimelineResource.lottie(animation)
//                globalResourceCache.setObject(ResourceWrapper(resource: resource), forKey: params.storableKey as NSString)
//                _fireResource(params: params, resource: .value(resource), on: completionQueue)
//            }
//            else {
//                let resource = JMTimelineResource.raw(data)
//                globalResourceCache.setObject(ResourceWrapper(resource: resource), forKey: params.storableKey as NSString)
//                _fireResource(params: params, resource: .value(resource), on: completionQueue)
//            }
//        }
}
