//
//  RemoteStorageSubFilesUp.swift
//  App
//
//  Created by Stan Potemkin on 08.11.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation

import JMCodingKit
import SwiftMime

enum RemoteStorageSubFilesProtoSubject: IProtoEventSubject {
    case fileCredentials(ProtoEventSubjectPayload.FileCredentials)
}

class RemoteStorageSubFilesUp: IRemoteStorageSubEngineUp {
    private let thread: JVIDispatchThread
    private let userContext: IBaseUserContext
    private let networking: INetworking
    private let networkingHelper: INetworkingHelper
    
    private let retrieveCredentialsKindID = UUID()
    
    init(thread: JVIDispatchThread, userContext: IBaseUserContext, networking: INetworking, networkingHelper: INetworkingHelper) {
        self.thread = thread
        self.userContext = userContext
        self.networking = networking
        self.networkingHelper = networkingHelper
    }
    
    func upload(center: String, auth: NetworkingHelperAuth, item: RemoteStorageItem, completion: @escaping (Result<InternalMeta, RemoteStorageFileUploadError>) -> Void) {
        journal(layer: .logic, unimessage: {"file-exchange-upload-url[\(item.filePath ?? String())]"})
        
        let context = CommonFileContext(file: item.file) { [unowned self] ack in
            thread.async {
                switch ack {
                case .success(let info):
                    let meta = InternalMeta(
                        mime: item.file.mime,
                        key: info.key,
                        link: info.link,
                        size: item.file.contents.count
                    )
                    
                    completion(.success(meta))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        let contextID = networking.contextual(object: context).flushContext()
        userContext.havingAccess { [unowned self] in
            let options = RestRequestOptions(
                behavior: .regular,
                method: .get,
                headers: networkingHelper.generateHeaders(
                    auth: auth,
                    requestId: .auto,
                    contentType: nil),
                query: item.file.params,
                body: .omit
            )
            
            networking.send(
                output: .rest(
                    kindID: retrieveCredentialsKindID,
                    target: .build(
                        scope: .api,
                        path: center
                    ),
                    options: options,
                    contextID: contextID
                ),
                caching: .auto)
        }
    }
    
    func decodeToSubject(event: NetworkingSubject) -> IProtoEventSubject? {
        switch event {
        case .rest(.response(retrieveCredentialsKindID, _, let response)):
            return decodeFileCredentials(status: response.status, json: response.body)
        default:
            return nil
        }
    }
    
    private func decodeFileCredentials(status: RestResponseStatus, json: JsonElement) -> IProtoEventSubject? {
        let root = json.has(key: "access_credential") ?? json
        
        guard
            let url = URL(string: root["url"].stringValue),
            let _ = root.has(key: "key")
        else {
            return nil
        }
        
        let config = HTTPFileUploadConfig(
            url: url,
            key: root["key"].stringValue,
            date: root["date"].stringValue,
            policy: root["policy"].stringValue,
            credential: root["credential"].stringValue,
            algorithm: root["algorithm"].stringValue,
            signature: root["signature"].stringValue
        )
        
        return RemoteStorageSubFilesProtoSubject.fileCredentials(
            ProtoEventSubjectPayload.FileCredentials(
                status: status,
                body: .init(config: config)
            )
        )
    }
    
    func decodeToBundle(event: NetworkingSubject) -> ProtoEventBundle? {
        return nil
    }
    
    func handleProtoEvent(subject: IProtoEventSubject, context: ProtoEventContext?) {
        switch subject as? RemoteStorageSubFilesProtoSubject {
        case .fileCredentials(let payload):
            handleFileCredentials(payload, context: context)
        default:
            break
        }
    }
    
    func handleProtoEvent(transaction: [NetworkingEventBundle]) {
    }
    
    private func handleFileCredentials(_ meta: ProtoEventSubjectPayload.FileCredentials, context: ProtoEventContext!) {
        guard let object = context.object as? CommonFileContext else {
            return
        }
        
        switch meta.status {
        case .success:
            guard let config = meta.body.config else {
                return
            }
            
            performUploadToCloud(
                file: object.file,
                config: config,
                callback: object.callback)
            
        default:
            object.callback(.failure(.cannotPrepare))
//            notifyObservers(event: .mediaUploadFailure(withError: .extractionFailed), onQueue: .main)
        }
    }
    
    private func performUploadToCloud(file: HTTPFileConfig, config: HTTPFileUploadConfig, callback: @escaping (Result<RemoteStorageFileUploadInfo, RemoteStorageFileUploadError>) -> Void) {
        let adaptiveName = file.name
            .applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripDiacritics, reverse: false)?
            .lowercased()
            .replacingOccurrences(of: " ", with: "_") ?? file.name
        
        let multipart = MultipartFormData()
        
        if let value = Data.jv_with(string: file.access, encoding: .utf8) {
            multipart.append(value, withName: "acl")
        }
        
        if let value = Data.jv_with(string: config.key, encoding: .utf8) {
            multipart.append(value, withName: "key")
        }
        
        if let value = Data.jv_with(string: file.mime, encoding: .utf8), file.access != "private" {
            multipart.append(value, withName: "Content-Type")
        }
        
        if file.downloadable, let value = Data.jv_with(string: "attachment; filename*=UTF-8''\(adaptiveName)", encoding: .utf8) {
            multipart.append(value, withName: "Content-Disposition")
        }
        
        if let value = Data.jv_with(string: config.date, encoding: .utf8) {
            multipart.append(value, withName: "X-Amz-Date")
        }
        
        if let value = Data.jv_with(string: config.policy, encoding: .utf8) {
            multipart.append(value, withName: "Policy")
        }
        
        if let value = Data.jv_with(string: config.credential, encoding: .utf8) {
            multipart.append(value, withName: "X-Amz-Credential")
        }
        
        if let value = Data.jv_with(string: config.algorithm, encoding: .utf8) {
            multipart.append(value, withName: "X-Amz-Algorithm")
        }
        
        if let value = Data.jv_with(string: config.signature, encoding: .utf8) {
            multipart.append(value, withName: "X-Amz-Signature")
        }
        
        multipart.append(
            InputStream(data: file.contents),
            withLength: UInt64(file.contents.count),
            headers: [
                "Content-Disposition": "form-data; name=\"file\"; filename=\"\(adaptiveName)\"",
                "Content-Type": file.mime
            ]
        )
        
        guard let data = try? multipart.encode() else {
            callback(.failure(.cannotPrepare))
            return
        }
        
        var request = URLRequest(url: config.url)
        request.addValue(multipart.contentType, forHTTPHeaderField: "Content-Type")
        request.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        request.httpMethod = "POST"
        request.httpBody = data
        
        URLSession.shared
            .dataTask(with: request, completionHandler: { data, response, error in
                DispatchQueue.main.async {
                    if (response as? HTTPURLResponse)?.statusCode == 204 {
                        let link = config.url.absoluteString + "/" + config.key
                        let value = RemoteStorageFileUploadInfo(key: config.key, link: link)
                        callback(.success(value))
                    }
                    else {
                        callback(.failure(.unknown(statusCode: nil, error: nil)))
                    }
                }
            })
            .resume()
    }
    
}

extension ProtoEventSubjectPayload {
    struct FileCredentials: IProtoEventSubjectPayloadModel {
        struct Body {
            let config: HTTPFileUploadConfig?
        }
        
        static let kindID = UUID()
        let status: RestResponseStatus
        let body: Body
    }
}

fileprivate extension URL {
    var normalizedExtension: String? {
        return lastPathComponent.jv_fileExtension?.lowercased()
    }
}
