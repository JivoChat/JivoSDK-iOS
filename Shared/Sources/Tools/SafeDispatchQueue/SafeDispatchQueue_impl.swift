//
//  SafeDispatchQueue_impl.swift
//  App
//
//  Created by Stan Potemkin on 28.12.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

final class JVSafeDispatchQueue: DispatchQueue {
    private var suspensionsNumber = 0
    
    func safeSuspend(mutex: NSLock) {
        mutex.lock()
        defer {
            mutex.unlock()
        }
        
        suspend()
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
        
        resume()
        suspensionsNumber -= 1
    }
}
