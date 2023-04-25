//
//  NetworkingSubSocketTypes.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
import JMCodingKit

enum NetworkingSubSocketBehavior {
    case raw
    case json
}

enum NetworkingSubSocketEvent {
    enum Payload {
        case raw(String)
        case legacy(String, JsonElement)
        case atom(String, JsonElement)
        case rpc(String, JsonElement)
        case rpcAck(UUID, RestResponseStatus, JsonElement)
        case unknown(JsonElement)
    }
    
    case open(identifier: UUID)
    case payload(Payload)
    case close(identifier: UUID, code: Int, reason: String, error: Error?)
}

protocol INetworkingSubSocket: AnyObject {
    var eventObservable: JVBroadcastTool<NetworkingSubSocketEvent> { get }
    var isConnecting: Bool { get }
    var isConnected: Bool { get }
    func connect(to url: URL, withHeaders headers: [String: String])
    func disconnect()
    func sendRaw(message: String, supportsCaching: Bool)
    func sendAtom(json: JsonElement, supportsCaching: Bool)
    func sendLegacy(name: String, body: JsonElement, supportsCaching: Bool)
    func sendRPC(requestID: UUID?, method: String, body: JsonElement, supportsCaching: Bool)
    func startCaching()
    func stopCaching(flush: Bool)
    func pauseListening()
    func resumeListening(flush: Bool)
}
