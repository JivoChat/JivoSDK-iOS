//
//  RemoteStorageSubMediaUp.swift
//  App
//
//  Created by Stan Potemkin on 07.11.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit
import SwiftMime

enum RemoteStorageSubMediaProtoSubject: IProtoEventSubject {
    case mediaCredentials(ProtoEventSubjectPayload.MediaCredentials)
}

final class RemoteStorageSubMediaUp: IRemoteStorageSubEngineUp {
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
    
    func upload(endpoint: String?, center: String, auth: NetworkingHelperAuth, item: RemoteStorageItem, completion: @escaping (Result<InternalMeta, RemoteStorageFileUploadError>) -> Void) {
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
                        endpoint: endpoint,
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
    
    func decodeToBundle(event: NetworkingSubject) -> ProtoEventBundle? {
        return nil
    }
    
    private func decodeFileCredentials(status: RestResponseStatus, json: JsonElement) -> IProtoEventSubject? {
        switch status {
        case .success:
            break
        case .badRequest:
            return RemoteStorageSubMediaProtoSubject.mediaCredentials(
                ProtoEventSubjectPayload.MediaCredentials(
                    status: status,
                    body: .init(result: .failure(.badRequest))
                )
            )
        case .unauthorized:
            return RemoteStorageSubMediaProtoSubject.mediaCredentials(
                ProtoEventSubjectPayload.MediaCredentials(
                    status: status,
                    body: .init(result: .failure(.unauthorized))
                )
            )
        case .notFound:
            return RemoteStorageSubMediaProtoSubject.mediaCredentials(
                ProtoEventSubjectPayload.MediaCredentials(
                    status: status,
                    body: .init(result: .failure(.notFound))
                )
            )
        case .unknown:
            return RemoteStorageSubMediaProtoSubject.mediaCredentials(
                ProtoEventSubjectPayload.MediaCredentials(
                    status: status,
                    body: .init(result: .failure(.unknown(statusCode: status.rawValue, error: nil)))
                )
            )
        default:
            return RemoteStorageSubMediaProtoSubject.mediaCredentials(
                ProtoEventSubjectPayload.MediaCredentials(
                    status: status,
                    body: .init(result: .failure(.unknown(statusCode: status.rawValue, error: nil)))
                )
            )
        }
        
        let root = json.has(key: "access_credential") ?? json
        
        guard !(root["error_list"].stringArray.contains("filetransfer_disabled"))
        else {
            return RemoteStorageSubMediaProtoSubject.mediaCredentials(
                ProtoEventSubjectPayload.MediaCredentials(
                    status: status,
                    body: .init(result: .failure(.fileTransferDisabled))
                )
            )
        }
        
        guard let url = URL(string: root["url"].stringValue),
              let metadata = root["metadata"].string,
              let sign = root["sign"].string,
              let ts = root["ts"].int
        else {
            return RemoteStorageSubMediaProtoSubject.mediaCredentials(
                ProtoEventSubjectPayload.MediaCredentials(
                    status: status,
                    body: .init(result: .failure(.unableToDecode))
                )
            )
        }
        
        let config = HTTPMediaUploadConfig(
            url: url,
            ts: ts,
            sign: sign,
            metadata: metadata
        )
        
        return RemoteStorageSubMediaProtoSubject.mediaCredentials(
            ProtoEventSubjectPayload.MediaCredentials(
                status: status,
                body: .init(result: .success(config))
            )
        )
    }
    
    func handleProtoEvent(subject: IProtoEventSubject, context: ProtoEventContext?) {
        switch subject as? RemoteStorageSubMediaProtoSubject {
        case .mediaCredentials(let payload):
            handleMediaCredentials(payload, context: context)
        default:
            break
        }
    }
    
    func handleProtoEvent(transaction: [NetworkingEventBundle]) {
    }
    
    private func handleMediaCredentials(_ meta: ProtoEventSubjectPayload.MediaCredentials, context: ProtoEventContext!) {
        guard let object = context.object as? CommonFileContext else {
            return
        }
        
        switch meta.body.result {
        case let .success(config):
            performUploadToCloud(
                file: object.file,
                config: config,
                callback: object.callback)
            
        case let .failure(error):
            object.callback(.failure(.unknown(statusCode: meta.status.rawValue, error: error)))
        }
    }
    
    private func performUploadToCloud(file: HTTPFileConfig, config: HTTPMediaUploadConfig, callback: @escaping (Result<RemoteStorageFileUploadInfo, RemoteStorageFileUploadError>) -> Void) {
        let adaptiveName = file.name
            .applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripDiacritics, reverse: false)?
            .lowercased()
            .replacingOccurrences(of: " ", with: "_") ?? file.name
        
        var components = URLComponents(string: config.url.absoluteString) ?? URLComponents()
        components.path = "/" + adaptiveName
        components.queryItems = [
            URLQueryItem(name: "sign", value: config.sign),
            URLQueryItem(name: "ts", value: String(describing: config.ts)),
            URLQueryItem(name: "public", value: nil),
        ]
        
        guard let url = components.url else {
            callback(.failure(.cannotPrepare))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue(file.mime, forHTTPHeaderField: "Content-Type")
        request.addValue("\(file.contents.count)", forHTTPHeaderField: "Content-Length")
        request.addValue(config.metadata, forHTTPHeaderField: "X-Metadata")
        request.httpBody = file.contents
        
        URLSession.shared
            .dataTask(with: request, completionHandler: { data, response, error in
                DispatchQueue.main.async {
                    guard let response = response as? HTTPURLResponse else {
                        callback(.failure(.unknown(statusCode: nil, error: error)))
                        return
                    }
                    
                    switch response.statusCode {
                    case 201:
                        let path = (response.allHeaderFields["Location"] as? String) ?? String()
                        let link = config.url.appendingPathComponent(path)
                        let info = RemoteStorageFileUploadInfo(key: path, link: link.absoluteString)
                        callback(.success(info))
                    case 415:
                        callback(.failure(.unsupportedFileType))
                    case 451:
                        callback(.failure(.possibleMalware))
                    default:
                        callback(.failure(.unknown(statusCode: response.statusCode, error: error)))
                    }
                }
            })
            .resume()
    }
}

extension ProtoEventSubjectPayload {
    struct MediaCredentials: IProtoEventSubjectPayloadModel {
        struct Body {
            let result: Result<HTTPMediaUploadConfig, RemoteStorageFileUploadError>
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
