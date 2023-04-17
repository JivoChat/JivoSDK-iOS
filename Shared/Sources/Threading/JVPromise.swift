//
//  JVPromise.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 31.10.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation

public final class JVPromise<Value> {
    private let queue: DispatchQueue
    private var block: ((Value) -> Void)?
    
    private let thread = Thread.current
    private let uid = UUID()
    
    public init(queue: DispatchQueue = .main, evaluate block: (JVPromise<Value>) -> Void) {
        self.queue = queue
        block(self)
    }
    
    public func listen(block: @escaping (Value) -> Void) {
        self.block = block
        thread.threadDictionary[uid] = self
    }
    
    public func provide(value: Value) {
        queue.async { [weak self] in
            self?.evaluate(value: value)
        }
    }
    
    private func evaluate(value: Value) {
        block?(value)
        block = nil
        
        thread.threadDictionary.removeObject(forKey: uid)
    }
}
