//
//  BroadcastService.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 20/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

struct JVBroadcastToolTag: OptionSet {
    let rawValue: Int
}

public struct JVBroadcastMeta<Value> {
    public let previous: Value?
    public let actual: Value
}

class JVBroadcastTool<Value> {
    public typealias Observer = (Value) -> Void
    public typealias MetaObserver = (JVBroadcastMeta<Value>) -> Void

    private var observers = [(UUID, Observer, JVBroadcastToolTag)]()
    private var convertingTokens = [Any]()
    private var observingTokens = [Any]()

    init() {
    }
    
    public subscript<Target>(_ type: Target.Type) -> JVBroadcastTool<Target> {
        let converter = JVBroadcastTool<Target>()
        convertingTokens.append(addObserver { value in converter.broadcast(value as! Target) })
        return converter
    }
    
    func addObserver(ignoring tags: JVBroadcastToolTag = [], _ observer: @escaping Observer) -> JVBroadcastObserver<Value> {
        let id = UUID()
        observers.append((id, observer, tags))
        return JVBroadcastObserver(ID: id, broadcastTool: self)
    }
    
    func attachObserver(ignoring tags: JVBroadcastToolTag = [], _ observer: Observer?) {
        guard let observer = observer else { return }
        let id = UUID()
        observers.append((id, observer, tags))
        observingTokens.append(JVBroadcastObserver(ID: id, broadcastTool: self))
    }
    
    func attachObserver(observer: @escaping Observer) {
        let id = UUID()
        observers.append((id, observer, []))
        observingTokens.append(JVBroadcastObserver(ID: id, broadcastTool: self))
    }
    
    func removeObserver(_ observer: JVBroadcastObserver<Value>) {
        let id = observer.ID
        
        if let index = observers.map({ $0.0 }).firstIndex(of: id) {
            observers.remove(at: index)
        }
    }
    
    func broadcast(_ value: Value, tag: JVBroadcastToolTag? = nil) {
        observers.forEach { observer in
            if let tag = tag, observer.2.contains(tag) {
                return
            }
            
            observer.1(value)
        }
    }
    
    func broadcast(_ value: Value) {
        broadcast(value, tag: nil)
    }
    
    func broadcast(_ value: Value, async queue: DispatchQueue) {
        let signal = self
        queue.async { signal.broadcast(value) }
    }
    
    func broadcast(_ value: Value, sync queue: DispatchQueue) {
        let signal = self
        queue.sync { signal.broadcast(value) }
    }
}
