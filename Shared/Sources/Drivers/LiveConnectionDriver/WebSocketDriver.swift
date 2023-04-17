//
//  WebSocketDriver.swift
//  App
//
//  Created by Anton Karpushko on 16.09.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit
import JFWebSocket


class WebSocketDriver: ILiveConnectionDriver {
    var openHandler: (() -> Void)?
    var messageHandler: ((Any) -> Void)?
    var closeHandler: ((Int, String, Error?) -> Void)?
    
    var isConnecting: Bool {
        return webSocket?.readyState == .connecting
    }
    var isConnected: Bool {
        return webSocket?.readyState == .open
    }
    
    private let pingTimeInterval: TimeInterval
    private let pongTimeInterval: TimeInterval
    private let pingCharacter: Character
    private let pongCharacter: Character
    private let signToRemove: String?
    private let signToAppend: String?
    
    private var rpcID = 0
    
    private var isOutgoingPackagesCaching = false
    private var isIncomingPackagesCaching: Bool {
        return incomingPackagesAccumulator != nil
    }
    
    private let jsonCoder = JsonCoder()
    private let websocketQueue = generateWebSocketQueue()
    private var webSocket: WebSocket?
    private var outgoingPackagesAccumulator: AccumulatorTool<Data>
    private var incomingPackagesAccumulator: TimedAccumulatorTool<String>?
    private weak var pingTimer: Timer?
    private weak var pongTimer: Timer?
    
    init(
        outgoingPackagesAccumulator: AccumulatorTool<Data>,
        incomingPackagesAccumulator: TimedAccumulatorTool<String>? = nil,
        pingTimeInterval: TimeInterval,
        pongTimeInterval: TimeInterval,
        pingCharacter: Character,
        pongCharacter: Character,
        signToRemove: String? = nil,
        signToAppend: String? = nil
    ) {
        self.outgoingPackagesAccumulator = outgoingPackagesAccumulator
        self.incomingPackagesAccumulator = incomingPackagesAccumulator
        self.pingTimeInterval = pingTimeInterval
        self.pongTimeInterval = pongTimeInterval
        self.pingCharacter = pingCharacter
        self.pongCharacter = pongCharacter
        self.signToAppend = signToAppend
        self.signToRemove = signToRemove
        
        incomingPackagesAccumulator?.releaseBlock = { [weak self] messages in
            self?.incomingPackagesAccumulatorReleased(withItems: messages)
        }
    }
    
    deinit {
        invalidateTimers()
    }
    
    func pause() {
        websocketQueue.suspend()
    }
    
    func resume() {
        websocketQueue.resume()
    }
    
    func isCachingEnabled() -> Bool {
        return isOutgoingPackagesCaching
    }
    
    func startCaching() {
        isOutgoingPackagesCaching = true
        
        journal(
            layer: .network,
            subsystem: .general,
            messages: [
                .full: {"WebSocketDriver: start-caching"}
            ]
        )
    }
    
    func stopCaching(flush: Bool) {
        isOutgoingPackagesCaching = false
        
        if flush {
            let outgoingPackages = outgoingPackagesAccumulator.release()
            outgoingPackages.forEach { package in
                webSocket?.send(package)
            }
            
            journal(
                layer: .network,
                subsystem: .general,
                messages: [
                    .full: {"WebSocketDriver: stop-caching; flush-packets[\(outgoingPackages.count)]"}
                ]
            )
        } else {
            journal(
                layer: .network,
                subsystem: .general,
                messages: [
                    .full: {"WebSocketDriver: stop-caching; no-flush"}
                ]
            )
        }
    }
    
    func open(url: URL, withHeaders headers: [String: String]) {
        disconnect()
        setupWebSocket()
        
        var urlRequest = URLRequest(url: url)
        headers.forEach { pair in
            urlRequest.setValue(pair.value, forHTTPHeaderField: pair.key)
        }
        
        webSocket?.open(request: urlRequest)
    }
    
    func send(json: JsonElement, supportsCaching: Bool) {
        guard let data = jsonCoder.encodeToBinary(json, encoding: .utf8) else { return }
        
        if isOutgoingPackagesCaching, supportsCaching {
            outgoingPackagesAccumulator.accumulate(data)

            journal(
                layer: .network,
                subsystem: .general,
                unimessage: {"socket-enqueue[json]: \(secureJson(json))"}
            )
        }
        else {
            webSocket?.send(data)
            schedulePingTimer()

            journal(
                layer: .network,
                subsystem: .general,
                unimessage: {"socket-send[json]: \(secureJson(json))"}
            )
        }
    }
    
    func send(command: String, body: JsonElement, supportsCaching: Bool) {
        let payload = body.merged(with: ["name": command])
        guard
            let data = jsonCoder.encodeToBinary(payload, encoding: .utf8)
            else { return }
        
        if isOutgoingPackagesCaching, supportsCaching {
            outgoingPackagesAccumulator.accumulate(data)

            journal(
                layer: .network,
                subsystem: .general,
                unimessage: {"socket-enqueue[legacy]: \(secureJson(payload))"}
            )
        }
        else {
            webSocket?.send(data)
            schedulePingTimer()

            journal(
                layer: .network,
                subsystem: .general,
                unimessage: {"socket-send[legacy]: \(secureJson(payload))"}
            )
        }
    }
    
    func call(method: String, params: JsonElement, supportsCaching: Bool) -> Int {
        rpcID += 1
        
        let payload = JsonElement(
            [
                "id": "\(rpcID)",
                "method": method,
                "params": params.dictObject
            ]
        )
        
        guard
            let data = jsonCoder.encodeToBinary(payload, encoding: .utf8)
            else { return rpcID }
        
        if isOutgoingPackagesCaching, supportsCaching {
            outgoingPackagesAccumulator.accumulate(data)

            journal(
                layer: .network,
                subsystem: .general,
                unimessage: {"socket-enqueue[rpc]: \(secureJson(payload))"}
            )
        }
        else {
            webSocket?.send(data)
            schedulePingTimer()

            journal(
                layer: .network,
                subsystem: .general,
                unimessage: {"socket-send[rpc]: \(secureJson(payload))"}
            )
        }
        
        return rpcID
    }
    
    func send(plain: String, supportsCaching: Bool) {
        guard let data = plain.data(using: .utf8) else { return }
        
        if isOutgoingPackagesCaching, supportsCaching {
            outgoingPackagesAccumulator.accumulate(data)
        }
        else {
            webSocket?.send(data)
            schedulePingTimer()
        }
    }
    
    func close() {
        webSocket?.close()
        invalidateTimers()
    }
    
    func disconnect() {
        close()
        webSocket?.event.open = {}
        webSocket?.event.message = { _ in }
        webSocket?.event.pong = { _ in }
        webSocket?.event.end = { _, _, _, _ in }
        webSocket = nil
        
        incomingPackagesAccumulator?.removeAllAccumulatedItems()
        incomingPackagesAccumulator?.stop()
    }
    
    private func schedulePingTimer() {
        pingTimer?.invalidate()
        pingTimer = {
            let timer = Timer(timeInterval: pingTimeInterval, repeats: true) { [weak self] timer in
                self?.websocketQueue.async {
                    self?.pingTimerFired(timer)
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            return timer
        }()
    }
    
    private func schedulePongTimer() {
        pongTimer?.invalidate()
        pongTimer = {
            let timer = Timer(timeInterval: pongTimeInterval, repeats: false) { [weak self] timer in
                self?.websocketQueue.async {
                    self?.pongTimerFired(timer)
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            return timer
        }()
    }
    
    private func invalidateTimers() {
        pingTimer?.invalidate()
        pongTimer?.invalidate()
    }
    
    private func pingTimerFired(_ timer: Timer) {
        guard isConnected else {
            journal (
                layer: .network,
                subsystem: .any,
                messages: [
                    .full: {"WebSocketDriver: not-connected; prevent-ping"}
                ]
            )
            
            return
        }
        
        webSocket?.send(String(pingCharacter).utf8)
    }
    
    private func pongTimerFired(_ timer: Timer) {
        journal(
            layer: .network,
            subsystem: .any,
            messages: [
                .full: {"WebSocketDriver: no-pong; perform-close"}
            ]
        )
        
        disconnect()
    }
    
    private func setupWebSocket() {
        webSocket = WebSocket()
        
        webSocket?.eventQueue = websocketQueue
        
        webSocket?.event.open = { [weak self] in
            self?.webSocketOpened()
        }
        
        webSocket?.event.message = { [weak self] message in
            self?.webSocketReceived(message: message)
        }
        
        webSocket?.event.pong = { [weak self] pong in
            self?.webSocketReceived(pong: pong)
        }
        
        webSocket?.event.end = { [weak self] code, reason, _, error in
            self?.webSocketClosedConnection(withCode: code, reason: reason, andError: error)
        }
    }
    
    private func webSocketOpened() {
        incomingPackagesAccumulator?.removeAllAccumulatedItems()
        
        schedulePingTimer()
        schedulePongTimer()
        
        openHandler?()
    }
    
    private func webSocketReceived(message: Any) {
        func _validateEnding(_ body: String) -> String {
            var mutatingBody = signToRemove.flatMap {
                return body.hasSuffix($0) ? String(body.dropLast($0.count)) : body
            } ?? body
            
            mutatingBody = signToAppend.flatMap {
                return !(mutatingBody.hasSuffix($0)) ? mutatingBody + $0 : mutatingBody
            } ?? mutatingBody
            
            return mutatingBody
        }
        
        schedulePongTimer()
        
        guard let message = message as? String else { return }
        
        if isIncomingPackagesCaching {
            incomingPackagesAccumulator?.accumulate(_validateEnding(message))
        } else {
            messageHandler?(_validateEnding(message))
        }
    }
    
    private func webSocketReceived(pong: Any) {
        schedulePongTimer()
    }
    
    private func webSocketClosedConnection(withCode code: Int, reason: String, andError error: Error?) {
        closeHandler?(code, reason, error)
        
        disconnect()
    }
    
    private func incomingPackagesAccumulatorReleased(withItems packages: [String]) {
        let accumulatedString = packages.joined()
        messageHandler?(accumulatedString)
    }
}

fileprivate func generateWebSocketQueue() -> DispatchQueue {
    let label = "com.jivosite.mobile.websocket:" + UUID().jv_shortString
    return DispatchQueue(label: label)
}
