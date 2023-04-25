//
//  LiveConnectionDriver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
import JMCodingKit
import JFWebSocket

fileprivate final class LiveConnectionClosingBehavior {
    private enum ReconnectingBehavior {
        case soonIncremental
        case nextDay
        case onlyManual
    }
    
    private enum LoggingBehavior {
        case fact
        case reason
    }
    
    private let shortDelayCodes: Set<Int> = [1005, 1006, 1011, 1012, 1013, 1014, 1015]
    private let neverRepeatCodes: Set<Int> = [1002, 1003, 1007, 1009, 1010]
    private let normalCode = 1000
    private let reasonlessCode = 1008
    
    private func detectReconnectingBehavior(closingCode: Int) -> ReconnectingBehavior {
        switch closingCode {
        case let code where shortDelayCodes.contains(code):
            return .soonIncremental
        case let code where neverRepeatCodes.contains(code):
            return .onlyManual
        case normalCode, reasonlessCode:
            return .nextDay
        default:
            return .nextDay
        }
    }
    
    private func detectLoggingBehavior(closingCode: Int) -> LoggingBehavior {
        let reconnectingBehavior = detectReconnectingBehavior(closingCode: closingCode)
        
        switch (closingCode, reconnectingBehavior) {
        case (_, .soonIncremental):
            return .fact
        case (_, .onlyManual):
            return .reason
        case (normalCode, _):
            return .reason
        case (reasonlessCode, _):
            return .fact
        case (_, .nextDay):
            return .reason
        }
    }
}

let connectionNormalCloseCode = 0
let connectionMissingPongCode = 1
let connectionSessionEndCode = 1000
let connectionAbsentCode = 1006
let connectionNotReachableCode = 1009
let connectionSecureFailureCode = 1200

protocol ILiveConnectionDriver: AnyObject {
    var openHandler: (() -> Void)? { get set }
    var messageHandler: ((Any) -> Void)? { get set }
    var closeHandler: ((Int, String, Error?) -> Void)? { get set }
    
    var isConnecting: Bool { get }
    var isConnected: Bool { get }
    
    func pause()
    func resume()
    
    func isCachingEnabled() -> Bool
    func startCaching()
    func stopCaching(flush: Bool)
    
    func open(url: URL, withHeaders headers: [String: String])
    func send(json: JsonElement, supportsCaching: Bool)
    func send(command: String, body: JsonElement, supportsCaching: Bool)
    func call(method: String, params: JsonElement, supportsCaching: Bool) -> Int
    func send(plain: String, supportsCaching: Bool)
    func close()
    func disconnect()
}

final class LiveConnectionDriver: ILiveConnectionDriver {
    enum CacheState {
        case disabled
        case waiting
        case caching(sinceDate: Date)
    }
    
    var openHandler: (() -> Void)?
    var messageHandler: ((Any) -> Void)?
    var closeHandler: ((Int, String, Error?) -> Void)?
    
    private let jsonCoder = JsonCoder()
    private let websocketQueue = generateWebSocketQueue()
    private let websocketMutex = NSLock()
    private var webSocket: WebSocket?
    private var outgoingCachedPackets: [Data]?
    
    private let flushingInterval: TimeInterval
    private let voip: Bool
    private let endingSign: String?
    private let jsonPrivacyTool: JVJsonPrivacyTool
    private var cacheState: CacheState

    private var incomingCachedPackets = [String]()
    private var wasConnected = false
    private var rpcID = 0
    private var closingCode: Int?
    
    private var cachingTimer: DispatchSourceTimer?
    private weak var pingTimer: Timer?
    private weak var pongTimer: Timer?
    
    init(flushingInterval: TimeInterval, voip: Bool, endingSign: String?, jsonPrivacyTool: JVJsonPrivacyTool) {
        self.flushingInterval = flushingInterval
        self.voip = voip
        self.endingSign = endingSign
        self.jsonPrivacyTool = jsonPrivacyTool
        self.cacheState = (flushingInterval > 0 ? .waiting : .disabled)
    }

    deinit {
        stopPonging()
        stopPinging()
    }
    
    var isConnecting: Bool {
        return (webSocket?.readyState == .connecting)
    }

    var isConnected: Bool {
        return (webSocket?.readyState == .open)
    }
    
    func pause() {
        websocketQueue.safeSuspend(mutex: websocketMutex)
    }
    
    func resume() {
        websocketQueue.safeResume(mutex: websocketMutex)
    }
    
    func isCachingEnabled() -> Bool {
        return (outgoingCachedPackets != nil)
    }
    
    func startCaching() {
        journal(
            layer: .network,
            subsystem: .general,
            messages: [
                .full: {"start-caching"}
            ]
        )

        outgoingCachedPackets = []
    }
    
    func stopCaching(flush: Bool) {
        defer { outgoingCachedPackets = nil }
        
        if flush, let webSocket = webSocket {
            if let packets = outgoingCachedPackets {
                journal(
                    layer: .network,
                    subsystem: .general,
                    messages: [
                        .full: {"stop-caching; flush-packets[\(packets.count)]"}
                    ]
                )

                packets.forEach(webSocket.send)
            }
            
            reshedulePinging()
        }
        else {
            journal(
                layer: .network,
                subsystem: .general,
                messages: [
                    .full: {"stop-caching; no-flush"}
                ]
            )
        }
    }
    
    func open(url: URL, withHeaders headers: [String: String]) {
        disconnect()
        cacheState = (flushingInterval > 0 ? .waiting : .disabled)

        let ws = WebSocket()
        webSocket = ws
        
        ws.eventQueue = websocketQueue
        
        ws.event.open = { [weak self] in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                
                self.wasConnected = true
                self.incomingCachedPackets.removeAll()
                self.reshedulePinging()
                self.openHandler?()
            }
        }
        
        ws.event.message = { [weak self] message in
            func _flush(body: Any) {
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    
                    self.stopPonging()
                    self.reshedulePinging()
                    self.messageHandler?(body)
                }
            }
            
            func _schedule() {
                guard let `self` = self else { return }
                
                let block = DispatchWorkItem { [unowned self] in
//                    log(.debug, "cache timed out")
                    
                    let string = self.incomingCachedPackets.joined()
                    self.incomingCachedPackets.removeAll()
                    
                    self.cacheState = .waiting
                    _flush(body: string)
                }
                
                let timer = DispatchSource.makeTimerSource(
                    flags: DispatchSource.TimerFlags(rawValue: 0),
                    queue: self.websocketQueue
                )
                
                timer.schedule(
                    deadline: .now() + DispatchTimeInterval.milliseconds(Int(self.flushingInterval * 1000)),
                    repeating: DispatchTimeInterval.never
                )
                
                timer.setEventHandler(handler: block)
                timer.resume()
                
                self.cachingTimer = timer
            }
            
            func _unschedule() {
                guard let `self` = self else { return }
                
                self.cachingTimer?.cancel()
            }

            func _validateEnding(_ body: String) -> String {
                guard let sign = self?.endingSign else { return body }
                guard !body.hasSuffix(sign) else { return body }
                return body + sign
            }
            
            if let `self` = self {
                switch self.cacheState {
                case .disabled:
//                    log(.debug, "cache is disabled")
                    _flush(body: message)
                    
                case .waiting:
//                    log(.debug, "cache is now active")
                    
                    self.cacheState = .caching(sinceDate: Date())
                    _schedule()
                    
                    if let string = message as? String {
                        self.incomingCachedPackets.append(_validateEnding(string))
                    }

                case .caching(let sinceDate):
                    if let string = message as? String {
                        if Date().timeIntervalSince(sinceDate) < self.flushingInterval {
//                            log(.debug, "cache is still active")
                            
                            self.incomingCachedPackets.append(_validateEnding(string))
                        }
                        else {
//                            log(.debug, "cache has to flush")
                            
                            let accumulatedString = self.incomingCachedPackets.joined() + _validateEnding(string)
                            self.incomingCachedPackets.removeAll()
                            
                            self.cacheState = .waiting
                            _flush(body: accumulatedString)
                        }
                    }
                }
            }
            
        }
        
        ws.event.pong = { [weak self] _ in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                
                self.stopPonging()
            }
        }
        
        ws.event.end = { [weak self] code, reason, _, error in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                
                self.cachingTimer?.cancel()
                self.incomingCachedPackets.removeAll()
                
                self.stopPonging()
                self.stopPinging()
                
                if let customCode = self.closingCode {
                    self.closingCode = nil
                    self.wasConnected = false
                    self.closeHandler?(customCode, reason, nil)
                }
                else if !self.wasConnected {
                    if String(describing: error).contains("-9802)") {
                        self.closeHandler?(abs(NSURLErrorSecureConnectionFailed), reason, error)
                    }
                    else {
                        self.closeHandler?(abs(NSURLErrorNotConnectedToInternet), reason, error)
                    }
                }
                else {
                    self.wasConnected = false
                    self.closeHandler?(code, reason, error)
                }
            }
        }
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        ws.open(request: request)
    }
    
    func send(json: JsonElement, supportsCaching: Bool) {
        guard
            let data = jsonCoder.encodeToBinary(json, encoding: .utf8)
            else { return }
        
        if isCachingEnabled(), supportsCaching {
            outgoingCachedPackets?.append(data)

            journal { [p = jsonPrivacyTool] in "socket-send-enqueue[legacy]: \(p.filter(json: json))"}
        }
        else {
            webSocket?.send(data)
            reshedulePinging()

            journal { [p = jsonPrivacyTool] in "socket-send-now[legacy]: \(p.filter(json: json))"}
        }
    }
    
    func send(command: String, body: JsonElement, supportsCaching: Bool) {
        let payload = body.merged(with: ["name": command])
        send(json: payload, supportsCaching: supportsCaching)
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
        
        if isCachingEnabled(), supportsCaching {
            outgoingCachedPackets?.append(data)

            journal { [p = jsonPrivacyTool] in "socket-send-enqueue[rpc]: \(p.filter(json: payload))"}
        }
        else {
            webSocket?.send(data)
            reshedulePinging()

            journal { [p = jsonPrivacyTool] in "socket-send-now[rpc]: \(p.filter(json: payload))"}
        }
        
        return rpcID
    }
    
    func send(plain: String, supportsCaching: Bool) {
        guard let data = plain.data(using: .utf8) else { return }
        
        if isCachingEnabled(), supportsCaching {
            outgoingCachedPackets?.append(data)
        }
        else {
            webSocket?.send(data)
            reshedulePinging()
        }
    }
    
    func close() {
        webSocket?.close()
    }
    
    func disconnect() {
        if let ws = webSocket {
            ws.event.open = { }
            ws.event.message = { _ in }
            ws.event.pong = { _ in }
            ws.event.end = { _, _, _, _ in }
            ws.close()
        }
        
        cachingTimer?.cancel()
        incomingCachedPackets.removeAll()
        
        stopPonging()
        stopPinging()
        
        webSocket = nil
    }
    
    private func reshedulePinging() {
        stopPinging()
        pingTimer = Timer.scheduledTimer(
            timeInterval: 15,
            target: self,
            selector: #selector(handlePingTimer),
            userInfo: nil,
            repeats: false
        )
    }
    
    private func stopPinging() {
        pingTimer?.invalidate()
    }
    
    private func reshedulePonging() {
        stopPonging()
        pongTimer = Timer.scheduledTimer(
            timeInterval: 10,
            target: self,
            selector: #selector(handlePongTimer),
            userInfo: nil,
            repeats: false
        )
    }
    
    private func stopPonging() {
        pongTimer?.invalidate()
    }
    
    @objc private func handlePongTimer() {
        journal(
            layer: .network,
            subsystem: .any,
            messages: [
                .full: {"no-pong; perform-close"}
            ]
        )
        
        closingCode = 1
        close()
    }
    
    @objc private func handlePingTimer() {
        guard isConnected else {
            journal(
                layer: .network,
                subsystem: .any,
                messages: [
                    .full: {"not-connected; prevent-ping"}
                ]
            )
            
            return
        }
        
        webSocket?.send(" ")
        reshedulePinging()
        reshedulePonging()
    }
}

fileprivate func generateWebSocketQueue() -> JVSafeDispatchQueue {
    let label = "com.jivosite.mobile.websocket:" + UUID().jv_shortString
    return JVSafeDispatchQueue(label: label, qos: .default)
}
