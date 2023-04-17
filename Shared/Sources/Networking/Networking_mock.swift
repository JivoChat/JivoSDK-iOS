//
//  NetworkingMock.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif
@testable import Jivo

class NetworkingMock: INetworking {
    var backsignal: JVBroadcastTool<Any> = JVBroadcastTool()
    
    var context: INetworkingContext {
        fatalError()
    }
    
    var eventObservable: JVBroadcastTool<NetworkingEvent> {
        fatalError()
    }
    
    var observable: JVBroadcastTool<Any> {
        return backsignal
    }
    
    var isConnecting: Bool {
        fatalError()
    }
    
    var isConnected: Bool {
        fatalError()
    }
    
    var primaryDomain: String {
        fatalError()
    }
    
    func setPreferredDomain(_ domain: NetworkingDomain) {
        fatalError()
    }
    
    func baseURL(module: String) -> URL {
        fatalError()
    }
    
    func attachProto(_ proto: IProto) {
        fatalError()
    }
    
    func connect(url: URL) {
        fatalError()
    }
    
    func disconnect() {
        fatalError()
    }
    
    func contextual(object: Any?) -> Self {
        fatalError()
    }
    
    func flushContext() -> UUID {
        backsignal = JVBroadcastTool()
        return UUID()
    }
    
    func silent() {
    }
    
    func send(output: NetworkingOutputSubject, caching: NetworkingOutputCaching) -> Self {
        fatalError()
    }
    
    func startCaching() {
        fatalError()
    }
    
    func stopCaching(flush: Bool) {
        fatalError()
    }
    
    func pauseListening() {
        fatalError()
    }
    
    func resumeListening(flush: Bool) {
        fatalError()
    }
    
    func cancelActiveRequests() {
        fatalError()
    }
    
    func cancelBackgroundRequests() {
        fatalError()
    }
    
    final func jv_flush(event: Any) {
        backsignal.broadcast(event)
        _ = flushContext()
    }
}
