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
    var openHandler: ((JournalChild?) -> Void)?
    var messageHandler: ((JournalChild?, Any) -> Void)?
    var closeHandler: ((JournalChild?, Int, String, Error?) -> Void)?
    
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
    private let jsonPrivacyTool: JVJsonPrivacyTool
    
    private var rpcID = 0
    
    private var isOutgoingPackagesCaching = false
    private var isIncomingPackagesCaching: Bool {
        return incomingPackagesAccumulator != nil
    }
    
    private let jsonCoder = JsonCoder()
    private let websocketQueue: DispatchQueue
    private var webSocket: WebSocketVerbose?
    private var outgoingPackagesAccumulator: AccumulatorTool<(JsonElement?, Data)>
    private var incomingPackagesAccumulator: TimedAccumulatorTool<String>?
    private weak var pingTimer: Timer?
    private weak var pongTimer: Timer?
    
    init(
        namespace: String,
        outgoingPackagesAccumulator: AccumulatorTool<(JsonElement?, Data)>,
        incomingPackagesAccumulator: TimedAccumulatorTool<String>? = nil,
        pingTimeInterval: TimeInterval,
        pongTimeInterval: TimeInterval,
        pingCharacter: Character,
        pongCharacter: Character,
        signToRemove: String? = nil,
        signToAppend: String? = nil,
        jsonPrivacyTool: JVJsonPrivacyTool
    ) {
        self.outgoingPackagesAccumulator = outgoingPackagesAccumulator
        self.incomingPackagesAccumulator = incomingPackagesAccumulator
        self.pingTimeInterval = pingTimeInterval
        self.pongTimeInterval = pongTimeInterval
        self.pingCharacter = pingCharacter
        self.pongCharacter = pongCharacter
        self.signToAppend = signToAppend
        self.signToRemove = signToRemove
        self.jsonPrivacyTool = jsonPrivacyTool
        
        websocketQueue = DispatchQueue(label: "\(namespace).networking.websocket-\(UUID().jv_shortString).queue")
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
    }
    
    func stopCaching(flush: Bool) {
        isOutgoingPackagesCaching = false
        
        if flush {
            let outgoingPackages = outgoingPackagesAccumulator.release()
            outgoingPackages.forEach { json, data in
                if let json = json {
                    webSocket?.chain?.journal(layer: .api, .full) { [p = jsonPrivacyTool] in "WebSocket: flush body=\(p.filter(json: json))"}
                }
                
                webSocket?.send(data)
            }
        }
    }
    
    func open(url: URL, withHeaders headers: [String: String]) {
        disconnect()
        setupWebSocket(url: url)
        
        var urlRequest = URLRequest(url: url)
        headers.forEach { pair in
            urlRequest.setValue(pair.value, forHTTPHeaderField: pair.key)
        }
        
        webSocket?.open(request: urlRequest)
    }
    
    func send(json: JsonElement, supportsCaching: Bool) {
        guard let data = jsonCoder.encodeToBinary(json, encoding: .utf8) else { return }
        
        if isOutgoingPackagesCaching, supportsCaching {
            outgoingPackagesAccumulator.accumulate((json, data))
        }
        else {
            webSocket?.chain?.journal(layer: .api) { [p = jsonPrivacyTool] in "WebSocket: send body=\(p.filter(json: json))"}
            webSocket?.send(data)
            schedulePingTimer()
        }
    }
    
    func send(command: String, body: JsonElement, supportsCaching: Bool) {
        let payload = body.merged(with: ["name": command])
        guard
            let data = jsonCoder.encodeToBinary(payload, encoding: .utf8)
            else { return }
        
        if isOutgoingPackagesCaching, supportsCaching {
            outgoingPackagesAccumulator.accumulate((payload, data))
        }
        else {
            webSocket?.chain?.journal(layer: .api) { [p = jsonPrivacyTool] in "WebSocket: send body=\(p.filter(json: payload))"}
            webSocket?.send(data)
            schedulePingTimer()
        }
    }
    
    func call(method: String, params: JsonElement, supportsCaching: Bool) -> Int {
        rpcID += 1
        
        let payload = JsonElement(
            [
                "id": "\(rpcID)",
                "method": method,
                "params": params.dictObject
            ] as [String: Any]
        )
        
        guard
            let data = jsonCoder.encodeToBinary(payload, encoding: .utf8)
            else { return rpcID }
        
        if isOutgoingPackagesCaching, supportsCaching {
            outgoingPackagesAccumulator.accumulate((payload, data))
        }
        else {
            webSocket?.chain?.journal(layer: .api) { [p = jsonPrivacyTool] in "WebSocket: send body=\(p.filter(json: payload))"}
            webSocket?.send(data)
            schedulePingTimer()
        }
        
        return rpcID
    }
    
    func send(plain: String, supportsCaching: Bool) {
        guard let data = plain.data(using: .utf8) else { return }
        
        if isOutgoingPackagesCaching, supportsCaching {
            outgoingPackagesAccumulator.accumulate((nil, data))
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
        if let ws = webSocket {
            closeHandler?(ws.chain, 0, String(), nil)
        }
        
        close()
        
        webSocket?.event.open = { }
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
            return
        }
        
        webSocket?.send(String(pingCharacter).utf8)
    }
    
    private func pongTimerFired(_ timer: Timer) {
        webSocket?.chain?.journal(layer: .network, .full) {"WebSocket: disconnect as no Pong arrived"}
        disconnect()
    }
    
    private func setupWebSocket(url: URL) {
        let chain = journal(layer: .api) {"WebSocket: setup for\n\(url.absoluteString)"}
        
        webSocket = WebSocketVerbose()
        webSocket?.chain = chain
        
        webSocket?.eventQueue = websocketQueue
        
        webSocket?.event.open = { [weak self] in
            self?.webSocketOpened(chain: chain)
        }
        
        webSocket?.event.message = { [weak self] message in
            self?.webSocketReceived(chain: chain, message: message)
        }
        
        webSocket?.event.pong = { [weak self] pong in
            self?.webSocketReceived(pong: pong)
        }
        
        webSocket?.event.end = { [weak self] code, reason, _, error in
            self?.webSocketClosedConnection(chain: chain, withCode: code, reason: reason, andError: error)
        }
    }
    
    private func webSocketOpened(chain: JournalChild) {
        incomingPackagesAccumulator?.releaseBlock = { [weak self] messages in
            self?.incomingPackagesAccumulatorReleased(chain: chain, withItems: messages)
        }
        
        incomingPackagesAccumulator?.removeAllAccumulatedItems()
        
        schedulePingTimer()
        schedulePongTimer()
        
        openHandler?(chain)
    }
    
    private func webSocketReceived(chain: JournalChild, message: Any) {
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
            messageHandler?(chain, _validateEnding(message))
        }
    }
    
    private func webSocketReceived(pong: Any) {
        schedulePongTimer()
    }
    
    private func webSocketClosedConnection(chain: JournalChild, withCode code: Int, reason: String, andError error: Error?) {
        closeHandler?(chain, code, reason, error)
        
        disconnect()
    }
    
    private func incomingPackagesAccumulatorReleased(chain: JournalChild, withItems packages: [String]) {
        let accumulatedString = packages.joined()
        messageHandler?(chain, accumulatedString)
    }
}
