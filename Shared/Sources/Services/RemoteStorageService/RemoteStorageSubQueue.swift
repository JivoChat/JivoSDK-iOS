//
//  RemoteStorageSubQueue.swift
//  App
//
//  Created by Stan Potemkin on 08.11.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation

import JMCodingKit
import SwiftMime

protocol IRemoteStorageSubQueue: AnyObject {
    func subscribeOn(_ subscribeBlock: @escaping ([RemoteStorageItem]) -> Void)
    func enqueue(itemID: String, target: RemoteStorageTarget, file: HTTPFileConfig, completion: @escaping (Result<RemoteStorageUploadedMeta, RemoteStorageFileUploadError>) -> Void)
    func uploadingStatus(target: RemoteStorageTarget) -> RemoteStorageUploadingStatus?
    func findUpload(uploadID: String) -> RemoteStorageUploadedMeta?
    func handleMediaMeta(media: RemoteStorageItem, meta: Result<InternalMeta, RemoteStorageFileUploadError>)
}

enum RemoteStorageUploadingStatus {
    case preparing
    case uploading
}

struct RemoteStorageUploadedMeta {
    let item: RemoteStorageItem
    let key: String
    let link: String
//    case cannotExtractData
//    case sizeLimitExceeded
//    case exportingFailed
//    case possible
//    case unknownError
    
    init(
        item: RemoteStorageItem,
        key: String,
        link: String
    ) {
        self.item = item
        self.key = key
        self.link = link
    }
}

final class RemoteStorageSubQueue: IRemoteStorageSubQueue {
    private let userContext: IBaseUserContext
    private let cacheDriver: ICacheDriver
    
    let eventSignal = JVBroadcastTool<[RemoteStorageItem]>()
    let activeItemSignal = JVBroadcastTool<RemoteStorageItem>()
    
    private var items = [RemoteStorageItem]()
    private var uploadIdToInfoMap = [String: RemoteStorageUploadedMeta]()
    private weak var activeItem: RemoteStorageItem?

    init(userContext: IBaseUserContext, cacheDriver: ICacheDriver) {
        self.userContext = userContext
        self.cacheDriver = cacheDriver
    }
    
    func subscribeOn(_ subscribeBlock: @escaping ([RemoteStorageItem]) -> Void) {
        eventSignal.attachObserver(observer: subscribeBlock)
    }
    
    func enqueue(itemID: String, target: RemoteStorageTarget, file: HTTPFileConfig, completion: @escaping (Result<RemoteStorageUploadedMeta, RemoteStorageFileUploadError>) -> Void) {
        guard let sessionID = userContext.remoteStorageToken else {
            return completion(.failure(.unknown(statusCode: nil, error: nil)))
        }
        
        guard file.contents.count <= uploadingSizeLimit else {
            journal {"::internal-enqueue size-limit"}
            completion(.failure(.sizeLimit))
            return
        }
        
        journal {"::internal-enqueue id[\(file.uploadID)]"}
        
        let change = RemoteStorageItem(
            ID: file.uploadID,
            sessionID: sessionID,
            filePath: nil,
            file: file,
            target: target,
            size: file.pixelSize,
            completion: completion
        )
        
        items.append(change)
        eventSignal.broadcast(items, async: .main)
        
        if let url = obtainTemporaryPath(forData: file.contents, withID: file.uploadID) {
            items.last?.filePath = url.path
            uploadNextMediaIfNeeded()
        }
        else {
            journal {"::internal-enqueue failure[tmp-path]"}
        }
    }
    
    func uploadingStatus(target: RemoteStorageTarget) -> RemoteStorageUploadingStatus? {
        let item = items.first { $0.target == target }
        return item.flatMap { return ($0.filePath == nil ? .preparing : .uploading) }
    }
    
    func findUpload(uploadID: String) -> RemoteStorageUploadedMeta? {
        return uploadIdToInfoMap[uploadID]
    }
    
    func handleMediaMeta(media: RemoteStorageItem, meta: Result<InternalMeta, RemoteStorageFileUploadError>) {
        activeItem = nil
        
        items = items.filter { $0 !== media }
        uploadNextMediaIfNeeded()
        
        switch meta {
        case .success(let value) where media.sessionID == userContext.remoteStorageToken:
            let info = RemoteStorageUploadedMeta(item: media, key: value.key, link: value.link)
            uploadIdToInfoMap[media.ID] = info
            DispatchQueue.main.async { media.completion(.success(info)) }
        case .success:
            DispatchQueue.main.async { media.completion(.failure(.unknown(statusCode: nil, error: nil))) }
        case .failure(let error):
            DispatchQueue.main.async { media.completion(.failure(error)) }
        }
    }
    
    private var uploadingSizeLimit: Int {
//        return userContext.techConfig.fileSizeLimit * 1024 * 1024
        return 10 * 1024 * 1024
    }
    
    private func obtainTemporaryPath(forData data: Data, withID ID: String) -> URL? {
        let item = CacheDriverItem(fileName: ID)
        guard let fileURL = cacheDriver.url(item: item) else { return nil }
        
        do {
            try data.write(to: fileURL)
            return fileURL
        }
        catch {
            return nil
        }
    }
    
    private func uploadNextMediaIfNeeded() {
        eventSignal.broadcast(items, async: .main)
        
        // MARK: Delete this in the future:
        activeItem = nil
        
        guard activeItem == nil else { return }
        guard let item = items.first else { return }
        
        guard item.sessionID == userContext.remoteStorageToken else {
            item.completion(.failure(.unknown(statusCode: nil, error: nil)))
            items.removeFirst()
            
            uploadNextMediaIfNeeded()
            return
        }
        
        guard let _ = item.filePath else {
            DispatchQueue.main.jv_delayed(seconds: 1) { [weak self] in self?.uploadNextMediaIfNeeded() }
            return
        }
        
        activeItem = item
        activeItemSignal.broadcast(item, async: .main)
    }
    
    private func cancelAllUploads() {
        items.forEach { $0.completion(.failure(.unknown(statusCode: nil, error: nil))) }
        items.removeAll()
    }
}

class RemoteStorageItem {
    var filePath: String?
    
    let ID: String
    let sessionID: String
    let file: HTTPFileConfig
    let target: RemoteStorageTarget
    let size: CGSize?
    let completion: (Result<RemoteStorageUploadedMeta, RemoteStorageFileUploadError>) -> Void
    
    init(ID: String,
         sessionID: String,
         filePath: String?,
         file: HTTPFileConfig,
         target: RemoteStorageTarget,
         size: CGSize?,
         completion: @escaping (Result<RemoteStorageUploadedMeta, RemoteStorageFileUploadError>) -> Void) {
        self.ID = ID
        self.sessionID = sessionID
        self.filePath = filePath
        self.file = file
        self.target = target
        self.size = size
        self.completion = completion
    }
    
    func copy(filePath: String?) -> RemoteStorageItem {
        return RemoteStorageItem(
            ID: ID,
            sessionID: sessionID,
            filePath: filePath,
            file: file,
            target: target,
            size: size,
            completion: completion)
    }
}

fileprivate extension URL {
    var normalizedExtension: String? {
        return lastPathComponent.jv_fileExtension?.lowercased()
    }
}
