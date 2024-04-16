//
//  RemoteStorageService.swift
//  App
//
//  Created by Stan Potemkin on 10.10.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation
import JMTimelineKit
import JMCodingKit
import Gzip
import SwiftUI

protocol IRemoteStorageService: IRemoteStorageServiceDown, IRemoteStorageServiceUp {
    func cleanupOldResources(age: TimeInterval)
}

protocol IRemoteStorageServiceDown {
    func retrieveURL(endpoint: String?, originURL: URL, quality: RemoteStorageQuality, on completionQueue: DispatchQueue, completion: @escaping (URL?) -> Void)
    func retrieveCachedURL(originURL: URL, quality: RemoteStorageQuality) -> URL?
    func retrieveFile(endpoint: String?, originURL: URL, quality: RemoteStorageQuality, caching: RemoteStorageCaching, on callbackQueue: DispatchQueue, callback: @escaping (RemoteStorageFileResource) -> Void)
    func retrieveMeta(endpoint: String?, originURL: URL, caching: RemoteStorageCaching, on completionQueue: DispatchQueue, completion: @escaping (Result<RemoteStorageFileInfo, RemoteStorageFileInfoError>) -> Void)
}

protocol IRemoteStorageServiceUp {
    var observable: JVBroadcastTool<[RemoteStorageItem]> { get }
    func subscribeOn(_ subscribeBlock: @escaping ([RemoteStorageItem]) -> Void)
    func upload(endpoint: String?, target: RemoteStorageTarget, file: HTTPFileConfig, completion: @escaping (Result<RemoteStorageUploadedMeta, RemoteStorageFileUploadError>) -> Void)
    func uploadingStatus(target: RemoteStorageTarget) -> RemoteStorageUploadingStatus?
    func findUpload(uploadID: String) -> RemoteStorageUploadedMeta?
}

protocol IRemoteStorageSubEngineUp: INetworkingEventDecoder, INetworkingEventHandler {
    func upload(endpoint: String?, center: String, auth: NetworkingHelperAuth, item: RemoteStorageItem, completion: @escaping (Result<InternalMeta, RemoteStorageFileUploadError>) -> Void)
}

struct RemoteStorageCenter {
    let engine: RemoteStorageEngine
    let path: String
    let auth: NetworkingHelperAuth
    
    init(
        engine: RemoteStorageEngine,
        path: String,
        auth: NetworkingHelperAuth
    ) {
        self.engine = engine
        self.path = path
        self.auth = auth
    }
}

enum RemoteStorageEngine {
    case files
    case media
}

struct RemoteStorageTarget: Equatable {
    struct Purpose: Equatable {
        let name: String
        
        init(name: String) {
            self.name = name
        }
    }
    
    let purpose: Purpose
    let context: AnyHashable
    
    init(purpose: Purpose, context: AnyHashable) {
        self.purpose = purpose
        self.context = context
    }
}

enum RemoteStorageQuality: Hashable {
    case preview(width: CGFloat)
    case original
}

enum RemoteStorageCaching {
    case enabled
    case disabled
}

enum RemoteStorageFileKind {
    case image(UIImage)
    case lottie
    case video
    case binary
}

enum RemoteStorageFilePurpose {
    case origin
    case preview
}

enum RemoteStorageFileResource {
    case waiting
    
    case failure(error: RemoteStorageResourceRetrievingError)
    
    struct ValueMeta { let mime: String, originUrl: URL, localUrl: URL, purpose: RemoteStorageFilePurpose }
    case value(meta: ValueMeta, kind: RemoteStorageFileKind)
}

enum RemoteStorageResourceRetrievingError {
    case unauthorized
    case forbidden
    case notFound
    case unableToSignURL
    case unknown(statusCode: Int?, error: Error?)
}

struct RemoteStorageFileInfo {
    let name: String
}

enum RemoteStorageFileInfoError: Error {
    case unauthorized
    case notFound
    case unableToDecode
    case notFromCloudStorage
    case unknown(statusCode: Int?, error: Error?)
}

struct RemoteStorageFileUploadInfo {
    let key: String
    let link: String
}

enum RemoteStorageFileUploadError: Error {
    case cannotPrepare
    case sizeLimit
    case unauthorized
    case notFound
    case forbidden
    case fileTransferDisabled
    case unsupportedFileType
    case possibleMalware
    case invalidRequestURL
    case unableToDecode
    case badRequest
    case unknown(statusCode: Int?, error: Error?)
}

final class RemoteStorageService: IRemoteStorageService {
    private let userContext: IBaseUserContext
    private let cacheDriver: ICacheDriver
    private let keychainDriver: IKeychainDriver
    private let centerProvider: (RemoteStorageTarget.Purpose) -> RemoteStorageCenter?
    private let urlBuilder: NetworkingUrlBuilder
    
    private let subQueue: RemoteStorageSubQueue
    private let filesUp: IRemoteStorageSubEngineUp
    private let filesDown: IRemoteStorageServiceDown
    private let mediaUp: IRemoteStorageSubEngineUp
    private let mediaDown: IRemoteStorageServiceDown
    
    private let cachingDirectory = "remote-storage"
    
    init(thread: JVIDispatchThread, userContext: IBaseUserContext, networking: INetworking, networkingHelper: INetworkingHelper, networkEventDispatcher: INetworkingEventDispatcher, cacheDriver: ICacheDriver, keychainDriver: IKeychainDriver, centerProvider: @escaping (RemoteStorageTarget.Purpose) -> RemoteStorageCenter?, tokenProvider: @escaping () -> String?, urlBuilder: @escaping NetworkingUrlBuilder) {
        self.userContext = userContext
        self.cacheDriver = cacheDriver
        self.keychainDriver = keychainDriver
        self.centerProvider = centerProvider
        self.urlBuilder = urlBuilder
        
        subQueue = RemoteStorageSubQueue(
            userContext: userContext,
            cacheDriver: cacheDriver
        )
        
        filesUp = RemoteStorageSubFilesUp(
            thread: thread,
            userContext: userContext,
            networking: networking,
            networkingHelper: networkingHelper
        )
        
        filesDown = RemoteStorageSubFilesDown(
            cacheDriver: cacheDriver,
            cachingDirectory: cachingDirectory,
            tokenProvider: tokenProvider
        )
        
        mediaUp = RemoteStorageSubMediaUp(
            thread: thread,
            userContext: userContext,
            networking: networking,
            networkingHelper: networkingHelper
        )
        
        mediaDown = RemoteStorageSubMediaDown(
            networking: networking,
            cacheDriver: cacheDriver,
            cachingDirectory: cachingDirectory,
            tokenProvider: tokenProvider,
            urlBuilder: urlBuilder
        )
        
        subQueue.activeItemSignal.attachObserver { [unowned self] item in
            performMediaUploading(media: item)
        }
        
        networkEventDispatcher.register(decoder: filesUp, handler: filesUp)
        networkEventDispatcher.register(decoder: mediaUp, handler: mediaUp)
    }
    
    func subscribeOn(_ subscribeBlock: @escaping ([RemoteStorageItem]) -> Void) {
        subQueue.subscribeOn(subscribeBlock)
    }
    
    func retrieveURL(endpoint: String?, originURL: URL, quality: RemoteStorageQuality, on completionQueue: DispatchQueue, completion: @escaping (URL?) -> Void) {
        let engine = pickEngineDown(url: originURL)
        engine.retrieveURL(
            endpoint: endpoint,
            originURL: originURL,
            quality: quality,
            on: completionQueue,
            completion: completion)
    }
    
    func retrieveCachedURL(originURL: URL, quality: RemoteStorageQuality) -> URL? {
        let engine = pickEngineDown(url: originURL)
        return engine.retrieveCachedURL(
            originURL: originURL,
            quality: quality
        )
    }
    
    func retrieveFile(endpoint: String?, originURL: URL, quality: RemoteStorageQuality, caching: RemoteStorageCaching, on callbackQueue: DispatchQueue, callback: @escaping (RemoteStorageFileResource) -> Void) {
        let engine = pickEngineDown(url: originURL)
        engine.retrieveFile(
            endpoint: endpoint,
            originURL: originURL,
            quality: quality,
            caching: caching,
            on: callbackQueue,
            callback: callback)
    }
    
    func retrieveMeta(endpoint: String?, originURL: URL, caching: RemoteStorageCaching, on completionQueue: DispatchQueue, completion: @escaping (Result<RemoteStorageFileInfo, RemoteStorageFileInfoError>) -> Void) {
        let engine = pickEngineDown(url: originURL)
        engine.retrieveMeta(
            endpoint: endpoint,
            originURL: originURL,
            caching: caching,
            on: completionQueue,
            completion: completion)
    }
    
    func cleanupOldResources(age: TimeInterval) {
        let directoryItem = CacheDriverItem(
            directoryName: cachingDirectory,
            fileName: String()
        )
        
        let olderBound = Date().addingTimeInterval(-age)
        cacheDriver.cleanUp(directoryItem: directoryItem, olderThen: olderBound)
    }
    
    var observable: JVBroadcastTool<[RemoteStorageItem]> {
        return subQueue.eventSignal
    }
    
    func upload(endpoint: String?, target: RemoteStorageTarget, file: HTTPFileConfig, completion: @escaping (Result<RemoteStorageUploadedMeta, RemoteStorageFileUploadError>) -> Void) {
        subQueue.enqueue(
            endpoint: endpoint,
            itemID: file.uploadID,
            target: target,
            file: file,
            completion: completion)
    }
    
    func uploadingStatus(target: RemoteStorageTarget) -> RemoteStorageUploadingStatus? {
        return subQueue.uploadingStatus(target: target)
    }

    func findUpload(uploadID: String) -> RemoteStorageUploadedMeta? {
        return subQueue.findUpload(uploadID: uploadID)
    }
    
    private func detectMediaEngine(url: URL) -> Bool {
        if let host = url.host, host.hasPrefix("media") {
            return true
        }
        else {
            return false
        }
    }
    
    private func pickEngineDown(url: URL) -> IRemoteStorageServiceDown {
        return detectMediaEngine(url: url) ? mediaDown : filesDown
    }
    
    private func pickEngineUp(url: URL) -> IRemoteStorageSubEngineUp {
        return detectMediaEngine(url: url) ? mediaUp : filesUp
    }
    
    private func performMediaUploading(media: RemoteStorageItem) {
        guard let center = centerProvider(media.target.purpose) else {
            return subQueue.handleMediaMeta(media: media, meta: .failure(.invalidRequestURL))
        }
        
        let engine: IRemoteStorageSubEngineUp = {
            switch center.engine {
            case .files: return filesUp
            case .media: return mediaUp
            }
        }()
        
        engine.upload(endpoint: media.endpoint, center: center.path, auth: center.auth, item: media) { [unowned self] result in
            subQueue.handleMediaMeta(media: media, meta: result)
        }
    }
}

struct CommonFileContext {
    let file: HTTPFileConfig
    let callback: (Result<RemoteStorageFileUploadInfo, RemoteStorageFileUploadError>) -> Void
}
