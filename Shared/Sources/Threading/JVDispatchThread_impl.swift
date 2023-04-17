//
//  JVDispatchThread.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 28.10.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation

public final class JVDispatchThread: NSObject, JVIDispatchThread {
    private var thread: Thread?
    
    public init(caption: String) {
        super.init()
        
        let ref = Thread {
            RunLoop.current.add(Port(), forMode: .default)
            RunLoop.current.run()
        }
        
        thread = ref
        ref.name = caption
        ref.start()
    }
    
    public func async(block: @escaping () -> Void) {
        guard let ref = thread else {
            return
        }
        
        perform(
            #selector(handleTask),
            on: ref,
            with: DispatchTask(block: block),
            waitUntilDone: false,
            modes: [RunLoop.Mode.default.rawValue])
    }
    
    public func sync(block: @escaping () -> Void) {
        guard let ref = thread else {
            return
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        defer { semaphore.wait() }
        
        perform(
            #selector(handleTask),
            on: ref,
            with: DispatchTask {
                block()
                semaphore.signal()
            },
            waitUntilDone: false,
            modes: [RunLoop.Mode.default.rawValue])
    }
    
    public func stop() {
        thread?.cancel()
    }
    
    public func addOperation(_ block: @escaping () -> Void) {
        async(block: block)
    }
    
    @objc private func handleTask(task: DispatchTask) {
        task.perform()
    }
}

fileprivate final class DispatchTask: NSObject {
    private let block: () -> Void
    
    init(block: @escaping () -> Void) {
        self.block = block
        super.init()
    }
    
    func perform() {
        block()
    }
}
