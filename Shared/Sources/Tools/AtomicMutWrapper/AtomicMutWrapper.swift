//
//  AtomicMutWrapper.swift
//  App
//
//  Created by Stan Potemkin on 12.12.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

@propertyWrapper
class AtomicMut<Value> {
    private var value: Value
    private let mutex = NSRecursiveLock()
    
    init(wrappedValue value: Value) {
        self.value = value
    }
    
    var wrappedValue: Value {
        get {
            mutex.lock()
            defer { mutex.unlock() }
            return value
        }
        set {
            mutex.lock()
            defer { mutex.unlock() }
            value = newValue
        }
    }
    
    var projectedValue: AtomicMut<Value> {
        return self
    }
    
    func mutate<Result>(_ block: (inout Value) -> Result) -> Result {
        mutex.lock()
        defer { mutex.unlock() }
        return block(&value)
    }
}
