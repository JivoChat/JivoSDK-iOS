//
//  SafeDispatchQueue_impl.swift
//  App
//
//  Created by Stan Potemkin on 28.12.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

@propertyWrapper
final class JVSafeDispatching {
    private var queue: DispatchQueue
    private var suspensionsNumber = 0
    
    init(wrappedValue: DispatchQueue) {
        self.queue = wrappedValue
    }
    
    var wrappedValue: DispatchQueue {
        get {
            return queue
        }
        set {
            queue = newValue
        }
    }
    
    func safeSuspend(mutex: NSLock) {
        mutex.lock()
        defer {
            mutex.unlock()
        }
        
        queue.suspend()
        suspensionsNumber += 1
    }
    
    func safeResume(mutex: NSLock) {
        mutex.lock()
        defer {
            mutex.unlock()
        }
        
        guard suspensionsNumber > 0
        else {
            return
        }
        
        queue.resume()
        suspensionsNumber -= 1
    }
}
