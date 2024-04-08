//
//  NetworkingSubSocket.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 03.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

final class NetworkingSubSocket: INetworkingSubSocket {
    private let driver: ILiveConnectionDriver
    private let networkingThread: JVIDispatchThread
    private let behavior: NetworkingSubSocketBehavior
    private let jsonPrivacyTool: JVJsonPrivacyTool
    
    private let decodingThread: JVDispatchThread
    private let jsonCoder = JsonCoder()
    private var isListening = true
    private var rawToParse = [String]()
    private var identifierToRID = [Int: UUID]()
    
    init(
        namespace: String,
        identifier: UUID,
        driver: ILiveConnectionDriver,
        networkingThread: JVIDispatchThread,
        behavior: NetworkingSubSocketBehavior,
        jsonPrivacyTool: JVJsonPrivacyTool
    ) {
        self.driver = driver
        self.networkingThread = networkingThread
        self.behavior = behavior
        self.jsonPrivacyTool = jsonPrivacyTool
        
        decodingThread = JVDispatchThread(caption: "\(namespace).networking.parser.queue")
        
        driver.openHandler = { [unowned self] chain in
            chain?.journal {"WebSocket: event opened"}
            
            let event = NetworkingSubSocketEvent.open(identifier: identifier)
            notity(event: event)
        }
        
        driver.messageHandler = { [unowned self] chain, data in
            guard let raw = data as? String else { return }
            guard raw.count > 1 else { return }

            if self.isListening {
                self.handleRaw(chain: chain, raw: raw)
            }
            else {
                self.rawToParse.append(raw)
            }
        }
        
        driver.closeHandler = { [unowned self] chain, code, reason, error in
            chain?.journal {"WebSocket: event closed"}
            
            let event = NetworkingSubSocketEvent.close(identifier: identifier, code: code, reason: reason, error: error)
            notity(event: event)
        }
    }
    
    let eventObservable = JVBroadcastTool<NetworkingSubSocketEvent>()
    
    var isConnecting: Bool {
        return driver.isConnecting
    }
    
    var isConnected: Bool {
        return driver.isConnected
    }
    
    func connect(to url: URL, withHeaders headers: [String: String]) {
        resumeListening(flush: false)
        driver.open(url: url, withHeaders: headers)
    }
    
    func disconnect() {
        driver.disconnect()
    }
    
    func sendRaw(message: String, supportsCaching: Bool) {
        driver.send(
            plain: message,
            supportsCaching: supportsCaching)
    }
    
    func sendAtom(json: JsonElement, supportsCaching: Bool) {
        driver.send(
            json: json,
            supportsCaching: supportsCaching)
    }
    
    func sendLegacy(name: String, body: JsonElement, supportsCaching: Bool) {
        driver.send(
            command: name,
            body: body,
            supportsCaching: supportsCaching)
    }
    
    func sendRPC(requestID: UUID?, method: String, body: JsonElement, supportsCaching: Bool) {
        let rpcID = driver.call(
            method: method,
            params: body,
            supportsCaching: supportsCaching)
        
        if let requestID = requestID {
            identifierToRID[rpcID] = requestID
        }
    }
    
    func startCaching() {
        journal {"WebSocket: caching start"}
        driver.startCaching()
    }
    
    func stopCaching(flush: Bool) {
        journal {"WebSocket: caching stop"}
        driver.stopCaching(flush: flush)
    }
    
    func pauseListening() {
        isListening = false
        rawToParse.removeAll()
        driver.pause()
    }
    
    func resumeListening(flush: Bool) {
        if flush {
            rawToParse.forEach { handleRaw(chain: nil, raw: $0) }
        }
        
        if !isListening {
            driver.resume()
        }
        
        isListening = true
        rawToParse.removeAll()
    }
    
    private func handleRaw(chain: JournalChild?, raw: String) {
        switch behavior {
        case .raw:
            let event = NetworkingSubSocketEvent.payload(.raw(raw))
            notity(event: event)

        case .json:
            decodingThread.async { [unowned self] in
                guard let json = self.jsonCoder.decode(raw: raw)
                else {
                    return
                }
                
                chain?.journal { [p = jsonPrivacyTool] in "WebSocket: event message body=\(p.filter(json: json))"}
                
                if let name = json["name"].string {
                    let event = NetworkingSubSocketEvent.payload(.legacy(name, json))
                    notity(event: event)
                }
                else if let method = json["method"].string {
                    let event = NetworkingSubSocketEvent.payload(.rpc(method, json["params"]))
                    notity(event: event)
                }
                else if let type = json["type"].string {
                    let event = NetworkingSubSocketEvent.payload(.atom(type, json))
                    notity(event: event)
                }
                else if let rpcID = json["id"].int ?? json["id"].string?.jv_toInt() {
                    if let requestID = identifierToRID.removeValue(forKey: rpcID) {
                        let status = json["status"].int.flatMap(RestResponseStatus.init) ?? .success
                        let payload = json["result"]
                        
                        let event = NetworkingSubSocketEvent.payload(.rpcAck(requestID, status, payload))
                        notity(event: event)
                    }
                }
                else {
                    let event = NetworkingSubSocketEvent.payload(.unknown(json))
                    notity(event: event)
                }
            }
        }
    }
    
    private func notity(event: NetworkingSubSocketEvent) {
        networkingThread.async { [unowned self] in
            eventObservable.broadcast(event)
        }
    }
}
