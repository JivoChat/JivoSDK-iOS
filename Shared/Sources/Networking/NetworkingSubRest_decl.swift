//
//  NetworkingSubRestTypes.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
import JMCodingKit

protocol INetworkingSubRest: AnyObject {
    var eventObservable: JVBroadcastTool<NetworkingSubRestEvent> { get }
    func request(requestID: UUID?, url: URL, options: RestRequestOptions)
    func upload(file: HTTPFileConfig, config: HTTPFileUploadConfig, callback: @escaping (HTTPUploadAck) -> Void)
    func upload(media: HTTPFileConfig, config: HTTPMediaUploadConfig, callback: @escaping (HTTPUploadAck) -> Void)
    func cancelActiveRequests()
    func cancelBackgroundRequests()
}

enum NetworkingSubRestEvent {
    typealias SubjectID = UUID
    typealias Context = Any
    
    struct Response {
        let status: RestResponseStatus
        let headers: [String: String] = [:]
        let body: JsonElement
    }
    
    case response(SubjectID, URL, Response)
}
