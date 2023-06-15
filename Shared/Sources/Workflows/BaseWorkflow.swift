//
//  BaseWorkflow.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 28/08/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

protocol AnyWorkflow: AnyObject {
    var type: String { get }
    var isExecuting: Bool { get }
    func cancel()
}

class BaseWorkflow<Env: OptionSet>: Operation, AnyWorkflow {
    let type: String
    
    private var mutex = pthread_mutex_t()
    private var unlockedEnv = Env.init()
    private(set) var backgroundTask = UIBackgroundTaskIdentifier.invalid
    
    init(type: String) {
        self.type = type
    }
    
    func runBackgroundTask() {
        guard backgroundTask == .invalid else { return }
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.stopBackgroundTask()
        }
    }
    
    func stopBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    
    func shouldAbortForFail(error: APIConnectionLoginError) -> Bool {
        switch error {
        case .badCredentials: return true
        case .channelLimit: return true
        case .nodeRedirect: return false
        case .sessionExpired: return false
        case .maintenance: return true
        case .technicalError: return true
        case .unknown: return true
        case .usersLimit: return true
        case .moved: return true
        case .textual: return true
        }
    }
    
    override func main() {
        pthread_mutex_init(&mutex, nil)
    }
    
    final func lock() {
        pthread_mutex_lock(&mutex)
    }
    
    final func unlock() {
        pthread_mutex_unlock(&mutex)
    }
    
    final func prepare() {
        pthread_mutex_init(&mutex, nil)
    }
    
    final func awaitFor(env: Env) {
        if unlockedEnv.intersection(env).isEmpty {
            lock()
        }
    }
    
    final func next(unlock env: Env) {
        if unlockedEnv.intersection(env).isEmpty {
            unlockedEnv = unlockedEnv.union(env)
            unlock()
        }
    }
    
    func stop() {
        cancel()
        unlock()
    }
    
    final func finish() {
        lock()
    }
    
    final func cleanup() {
        unlock()
    }
}
