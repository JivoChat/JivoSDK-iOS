//
//  BaseManager.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 17.07.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation

protocol IManager: INetworkingEventHandler {
    var protoAny: AnyObject & INetworkingEventDecoder { get }
    func subscribe()
    
    @discardableResult
    func run() -> Bool
    
    func pause()
    func resume()
    func reset()
}

class BaseManager: IManager {
    let thread: JVIDispatchThread
    let userContextAny: AnyObject
    let protoAny: AnyObject & INetworkingEventDecoder
    let networkEventDispatcher: INetworkingEventDispatcher
    
    private var isRunning = false
    
    init(thread: JVIDispatchThread,
         userContext: AnyObject,
         proto: AnyObject & INetworkingEventDecoder,
         networkEventDispatcher: INetworkingEventDispatcher) {
        self.thread = thread
        self.userContextAny = userContext
        self.protoAny = proto
        self.networkEventDispatcher = networkEventDispatcher
    }
    
    func subscribe() {
        networkEventDispatcher.register(decoder: protoAny, handler: self)
    }
    
    @discardableResult
    func run() -> Bool {
        if isRunning {
            return false
        }
        else {
            isRunning = true
            return true
        }
    }
    
    func pause() {
    }
    
    func resume() {
    }
    
    func reset() {
    }
    
    func handleProtoEvent(subject: IProtoEventSubject, context: ProtoEventContext?) {
    }
    
    func handleProtoEvent(transaction: [NetworkingEventBundle]) {
    }
}
