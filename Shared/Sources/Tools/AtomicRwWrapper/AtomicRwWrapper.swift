//
//  AtomicRwWrapper.swift
//  App
//
//  Created by Stan Potemkin on 27.05.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

@propertyWrapper
struct AtomicRw<Value> {
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
}
