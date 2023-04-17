//
//  ThrottlingQueue.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 24.11.2021.
//  Copyright © 2021 jivosite.mobile. All rights reserved.
//

import Foundation

protocol Queuing {
    init(queue: DispatchQueue, delay: TimeInterval)

    func enqueue(_ block: @escaping () -> Void)
}

class ThrottlingQueue: Queuing {
    let delay: TimeInterval
    let queue: DispatchQueue
    
    private var lastWorkItemStartDispatchTime: DispatchTime?
    private var workItems: [DispatchWorkItem] = []

    required init(queue: DispatchQueue, delay: TimeInterval) {
        self.queue = queue
        self.delay = delay
    }

    func enqueue(_ block: @escaping () -> Void) {
        let workItem = DispatchWorkItem(block: block)
        workItems.append(workItem)
        
        if let lastWorkItemStartDispatchTime = self.lastWorkItemStartDispatchTime {
            let delayedLastWorkItemStartDispatchTime = lastWorkItemStartDispatchTime + delay
            self.lastWorkItemStartDispatchTime = delayedLastWorkItemStartDispatchTime
            
            let dispatchTime: DispatchTime = max(.now(), delayedLastWorkItemStartDispatchTime)
            queue.asyncAfter(deadline: dispatchTime, execute: workItem)
            
            if DispatchTime.now() > delayedLastWorkItemStartDispatchTime {
                self.lastWorkItemStartDispatchTime = nil
            }
        } else {
            lastWorkItemStartDispatchTime = .now()
            
            queue.async(execute: workItem)
        }
    }
}
