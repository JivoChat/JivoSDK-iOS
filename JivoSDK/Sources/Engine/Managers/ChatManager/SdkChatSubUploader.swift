//
//  SdkChatSubUploader.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 20.11.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import SwiftMime
import JMCodingKit

struct ChatMedia {
    let name: String
    let mime: String?
    let url: URL
    let dataSize: Int?
}

enum ChatMediaUploadingError: Error {
    case cannotExtractData
    case sizeLimitExceeded(megabytes: Int)
    case networkClientError
    case cannotHandleUploadResult
    case uploadDeniedByAServer(errorDescription: String? = nil)
    case unsupportedMediaType
    case unknown(errorDescription: String? = nil)
}

protocol ISdkChatSubUploader {
    var uploadingAttachments: [ChatPhotoPickerObject] { get }
    func upload(attachments: [ChatPhotoPickerObject], clientId: Int, channelId: String, siteId: Int, completion: @escaping (Result<JVMessageContent, ChatMediaUploadingError>) -> Void)
}

class SdkChatSubUploader: ISdkChatSubUploader {
    // MARK: Constants
    private let JPEG_DATA_COMPRESSION_QUALITY = CGFloat(1.0)
    private let UNTITLED_IMAGE_NAME = "Untitled image"

    var uploadingAttachments: [ChatPhotoPickerObject] = []
    
    private var semaphore = CountingSemaphore(value: 0)
    
    private let uploadingQueue: DispatchQueue
    private let workerThread: JVIDispatchThread
    private let remoteStorageService: IRemoteStorageService
    
    init(uploadingQueue: DispatchQueue, workerThread: JVIDispatchThread, remoteStorageService: IRemoteStorageService) {
        self.uploadingQueue = uploadingQueue
        self.workerThread = workerThread
        self.remoteStorageService = remoteStorageService
    }
    
    deinit {
        semaphore.setCounter(to: 0)
    }
    
    func upload(attachments: [ChatPhotoPickerObject], clientId: Int, channelId: String, siteId: Int, completion: @escaping (Result<JVMessageContent, ChatMediaUploadingError>) -> Void) {
        uploadingQueue.async { [weak self] in
            attachments.forEach { attachment in
                guard let `self` = self else { return }
                
                self.uploadingAttachments.append(attachment)
                
                switch attachment.payload {
                case let .image(meta):
                    self.uploadImage(uuid: attachment.uuid, meta: meta, clientId: clientId, channelId: channelId, siteId: siteId) { result in
                        self.semaphore.setCounter(to: 0)
                        completion(result)
                    }
                    
                case let .file(meta):
                    self.uploadFile(uuid: attachment.uuid, meta: meta, clientId: clientId, channelId: channelId, siteId: siteId) { result in
                        self.semaphore.setCounter(to: 0)
                        completion(result)
                    }
                    
                case let .voice(meta):
                    self.uploadFile(uuid: attachment.uuid, meta: meta, clientId: clientId, channelId: channelId, siteId: siteId) { result in
                        self.semaphore.setCounter(to: 0)
                        completion(result)
                    }
                case .progress: break
                }
                
                self.semaphore.setCounter(to: -1)
            }
        }
    }
    
    private func uploadImage(uuid: UUID, meta: ChatPhotoPickerImageMeta, clientId: Int, channelId: String, siteId: Int, completion: @escaping (Result<JVMessageContent, ChatMediaUploadingError>) -> Void) {
        guard let imageData = meta.image.jpegData(compressionQuality: JPEG_DATA_COMPRESSION_QUALITY)
        else {
            journal {"Failed uploading the media: cannot extract the image data"}
            return completion(.failure(.cannotExtractData))
        }
        
        guard imageData.count <= SdkConfig.uploadingLimit.bytes
        else {
            journal {"Failed uploading the media: image size limit exceeded"}
            return completion(.failure(.sizeLimitExceeded(megabytes: SdkConfig.uploadingLimit.megabytes)))
        }
        
        let imageName = meta.name ?? meta.url?.lastPathComponent ?? meta.assetLocalId ?? UNTITLED_IMAGE_NAME
        let imageMime = meta.url.flatMap(mimeFrom(url:)) ?? "image/jpeg"
        
        uploadData(
            imageData,
            fileName: imageName,
            uuid: uuid,
            mimeType: imageMime,
            clientId: clientId,
            channelId: channelId,
            siteId: siteId,
            completion: completion)
    }
    
    private func uploadFile(uuid: UUID, meta: ChatPhotoPickerFileMeta, clientId: Int, channelId: String, siteId: Int, completion: @escaping (Result<JVMessageContent, ChatMediaUploadingError>) -> Void) {
        guard let fileSize = meta.url.jv_fileSize, fileSize <= SdkConfig.uploadingLimit.bytes
        else {
            journal {"Failed uploading the media: file size limit exceeded"}
            return completion(.failure(.sizeLimitExceeded(megabytes: SdkConfig.uploadingLimit.megabytes)))
        }
        
        guard let data = try? Data(contentsOf: meta.url)
        else {
            journal {"Failed uploading the media: cannot read the file contents"}
            return completion(.failure(.cannotExtractData))
        }
        
        uploadData(
            data,
            fileName: meta.name,
            uuid: uuid,
            mimeType: mimeFrom(url: meta.url),
            duration: meta.duration,
            clientId: clientId,
            channelId: channelId,
            siteId: siteId,
            completion: completion)
    }
    
    private func uploadData(_ data: Data, fileName: String, uuid: UUID, mimeType: String?, duration: Int? = nil, clientId: Int, channelId: String, siteId: Int, completion: @escaping (Result<JVMessageContent, ChatMediaUploadingError>) -> Void) {
        let target = RemoteStorageTarget(purpose: .exchange, context: 0)
        
        let file = HTTPFileConfig(
            uploadID: uuid.uuidString,
            name: fileName,
            mime: mimeType ?? "application/octet-stream",
            mediaType: nil,
            access: "public-read",
            downloadable: true,
            duration: duration,
            pixelSize: nil,
            contents: data,
            params: [
                JsonElement(key: "site_id", value: siteId),
                JsonElement(key: "public_id", value: channelId),
                JsonElement(key: "client_id", value: clientId),
                JsonElement(key: "file_name", value: fileName)
            ]
        )
        
        remoteStorageService.upload(target: target, file: file) { [weak self] result in
            // '_self' variable is using because of bug in Swift <5.5 compiler thinking that optional self reference in guard-condition else block is unavailable `self` variable declared in the beginning of guard-condition
            guard let _self = self else { self?.semaphore.setCounter(to: 0); return }
            
            _self.workerThread.async {
                let attachmentToRemoveIndex = _self.uploadingAttachments.firstIndex {
                    $0.uuid.uuidString == uuid.uuidString
                }
                let chatPhotoPickerObject = attachmentToRemoveIndex.flatMap { _self.uploadingAttachments.remove(at: $0) }
                
                switch result {
                case let .success(url):
                    if let chatPhotoPickerObject = chatPhotoPickerObject,
                       let content = _self.messageContentFor(
                        chatPhotoPickerObject: chatPhotoPickerObject,
                        fileName: fileName,
                        mimeType: mimeType ?? String(),
                        dataSize: data.count,
                        andURL: URL(string: url.link) ?? URL(fileURLWithPath: "/tmp/jivo/null")
                       ) {
                        completion(.success(content))
                    } else {
                        completion(.failure(.cannotHandleUploadResult))
                    }
                    
                case .failure(.invalidRequestURL), .failure(.unableToDecode):
                    completion(.failure(.networkClientError))

                case .failure(.unsupportedFileType):
                    completion(.failure(.unsupportedMediaType))
                    
                case .failure(.fileTransferDisabled):
                    completion(.failure(.uploadDeniedByAServer()))


                case .failure(.unknown(let statusCode, let error)):
                    #if DEBUG
                    let errorDescription = "Error \(statusCode.flatMap { " \($0.jv_toString())" } ?? ""): \(error?.localizedDescription ?? "")"
                    completion(.failure(.uploadDeniedByAServer(errorDescription: errorDescription)))
                    #else
                    journal {"Failed uploading"}
                        .nextLine {"Failed to upload the file"}
                    
                    completion(.failure(.uploadDeniedByAServer(errorDescription: loc["media_uploading_common_error"])))
                    #endif
                    
                case .failure(let error):
                    #if DEBUG
                    completion(.failure(.uploadDeniedByAServer(errorDescription: "Error: \(error)")))
                    #else
                    journal {"Failed uploading"}
                        .nextLine {"Failed to upload the file"}
                    
                    completion(.failure(.uploadDeniedByAServer(errorDescription: loc["media_uploading_common_error"])))
                    #endif
                }
                
                _self.semaphore.setCounter(to: 0)
            }
        }
    }
    
    private func messageContentFor(chatPhotoPickerObject: ChatPhotoPickerObject, fileName: String, mimeType: String, dataSize: Int, andURL url: URL) -> JVMessageContent? {
        switch chatPhotoPickerObject.payload {
        case .image:
            return JVMessageContent.photo(
                mime: mimeType,
                name: fileName,
                link: url.absoluteString,
                dataSize: dataSize,
                width: 0,
                height: 0
            )
            
        case .file:
            return JVMessageContent.file(
                mime: mimeType,
                name: fileName,
                link: url.absoluteString,
                size: dataSize
            )
            
        default: return nil
        }
    }
    
    private func mimeFrom(url: URL) -> String? {
        var mimeType: String?
        
        if let ext = url.lastPathComponent.jv_fileExtension?.lowercased() {
            mimeType = SwiftMime.mime(ext)
        }
        
        return mimeType
    }
}

struct CountingSemaphore {
    private(set) var counter: Int
    
    private let dispatchSemaphore: DispatchSemaphore
    
    init(value: Int) {
        counter = value
        self.dispatchSemaphore = DispatchSemaphore(value: value)
    }
    
    mutating func wait() {
        counter -= 1
        dispatchSemaphore.wait()
    }
    
    mutating func signal() {
        counter += 1
        dispatchSemaphore.signal()
    }
    
    mutating func setCounter(to newValue: Int) {
        let difference = abs(newValue - counter)
        if newValue > counter {
            (0..<difference).forEach { _ in
                signal()
            }
        } else {
            (0..<difference).forEach { _ in
                wait()
            }
        }
    }
}
