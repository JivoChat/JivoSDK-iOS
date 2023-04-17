//
//  NetworkingTypes.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

protocol INetworking: AnyObject {
    var context: INetworkingContext { get }
    var eventObservable: JVBroadcastTool<NetworkingEvent> { get }
    var observable: JVBroadcastTool<Any> { get }
    var isConnecting: Bool { get }
    var isConnected: Bool { get }
    var primaryDomain: String { get }
    func setPreferredDomain(_ domain: NetworkingDomain)
    func baseURL(module: String) -> URL
    func attachProto(_ proto: IProto)
    func connect(url: URL)
    func disconnect()
    func contextual(object: Any?) -> Self
    func flushContext() -> UUID
    func silent()
    
    @discardableResult
    func send(output: NetworkingOutputSubject, caching: NetworkingOutputCaching) -> Self
    
    func startCaching()
    func stopCaching(flush: Bool)
    func pauseListening()
    func resumeListening(flush: Bool)
    func cancelActiveRequests()
    func cancelBackgroundRequests()
}

enum NetworkingDomain {
    case auto
    case zone(ZoneId)
    case sandbox(SandboxId)
    case custom(CustomHost)
}

extension NetworkingDomain {
    enum ZoneId: String {
        case ru
        case com
    }
    
    typealias SandboxId = String
    typealias CustomHost = String
}

struct NetworkingEvent {
    let subject: NetworkingSubject
    let context: ProtoEventContext?
}

enum NetworkingOutputSubject {
    case raw(message: String)
    case legacy(name: String, params: [JsonElement])
    case rpc(kindID: UUID?, method: String, params: [JsonElement], contextID: UUID)
    case atom(type: String, context: String?, id: String?, data: String?)
    case rest(kindID: UUID?, target: RestConnectionTarget, options: RestRequestOptions, contextID: UUID)
    case file(file: HTTPFileConfig, upload: HTTPFileUploadConfig, callback: (HTTPUploadAck) -> Void)
    case media(media: HTTPFileConfig, upload: HTTPMediaUploadConfig, callback: (HTTPUploadAck) -> Void)
}

struct NetworkingAtomModel {
    let type: String
    let data: String?
    let id: String?
    let to: String?
    let from: String?
    let parent: String?
    let context: String?
}

enum NetworkingOutputCaching {
    case auto
    case enabled
    case disabled
}

enum NetworkingSubject {
    case socket(NetworkingSubSocketEvent)
    case rest(NetworkingSubRestEvent)
    case apns(NetworkingSubApnsEvent)
}
