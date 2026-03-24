//
//  NetworkingSlicer.swift
//  App
//
//  Created by Stan Potemkin on 20.08.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

protocol INetworkingSlicer: AnyObject {
    var signal: JVBroadcastTool<[NetworkingEventBundle]> { get }
    func take(_ bundle: NetworkingEventBundle)
}

final class NetworkingSlicer: INetworkingSlicer {
    
    // MARK: - Public properties
    
    let signal = JVBroadcastTool<[NetworkingEventBundle]>()
    
    // MARK: - Private properties
    
    private let defaultTimeInterval: TimeInterval
    private let prolongedTimeInterval: TimeInterval
    private let timersTolerance: TimeInterval
    
    private let state: State
    private final class State {
        private let queue: DispatchQueue
        var isTimingStarted = false
        var accumulatedBundles: [NetworkingEventBundle] = []
        var isDefaultTimePeriodElapsed = false
        
        init(namespace: String) {
            queue = DispatchQueue(label: "\(namespace).networking.slicer")
        }
        
        func sync<T>(block: @escaping @Sendable (State) -> T) -> T {
            return queue.sync {
                block(self)
            }
        }
        
        func async(block: @escaping @Sendable (State) -> Void) {
            return queue.async { [weak self] in
                if let self {
                    block(self)
                }
            }
        }
    }
    
    private var unrelatedPackagesTimer: Timer?
    private var relatedPackagesTimer: Timer?
    
    // MARK: - Init/deinit
    
    init(namespace: String, defaultTimeInterval: TimeInterval, prolongedTimeInterval: TimeInterval, timersTolerance: TimeInterval = 0) {
        self.defaultTimeInterval = defaultTimeInterval
        self.prolongedTimeInterval = prolongedTimeInterval
        self.timersTolerance = timersTolerance
        
        state = State(namespace: namespace)
    }
    
    deinit {
        invalidateTimers()
    }
    
    // MARK: - Public methods
    
    func take(_ bundle: NetworkingEventBundle) {
        state.async { [weak self] ref in
            ref.accumulatedBundles.append(bundle)
            
            if !ref.isTimingStarted {
                ref.isTimingStarted = true
                DispatchQueue.main.async {
                    self?.sync_initializeTimers()
                }
            }
        }
    }
    
    // MARK: - Private methods
    
    private func sync_initializeTimers() {
        invalidateTimers()
        
        recreateUnrelatedPackagesTimer()
        recreateRelatedPackagesTimer()
    }
    
    private func invalidateTimers() {
        unrelatedPackagesTimer?.invalidate()
        relatedPackagesTimer?.invalidate()
        
        unrelatedPackagesTimer = nil
        relatedPackagesTimer = nil
        
        state.async { ref in
            ref.isTimingStarted = false
        }
    }
    
    private func recreateUnrelatedPackagesTimer() {
        self.unrelatedPackagesTimer?.invalidate()
        let unrelatedPackagesTimer = Timer(timeInterval: defaultTimeInterval, repeats: true, block: { [weak self] timer in
            self?.unrelatedPackagesTimerDidFire(timer: timer)
        })
        unrelatedPackagesTimer.tolerance = timersTolerance
        self.unrelatedPackagesTimer = unrelatedPackagesTimer
        RunLoop.main.add(unrelatedPackagesTimer, forMode: .common)
    }
    
    private func recreateRelatedPackagesTimer() {
        self.relatedPackagesTimer?.invalidate()
        let relatedPackagesTimer = Timer(timeInterval: prolongedTimeInterval, repeats: true, block: { [weak self] timer in
            self?.relatedPackagesTimerDidFire(timer: timer)
        })
        relatedPackagesTimer.tolerance = timersTolerance
        self.relatedPackagesTimer = relatedPackagesTimer
        RunLoop.main.add(relatedPackagesTimer, forMode: .common)
    }
    
    private func unrelatedPackagesTimerDidFire(timer: Timer) {
        let (shouldBroadcast, shouldRecreateTimer) = state.sync { ref in
            defer {
                ref.isDefaultTimePeriodElapsed = true
            }
            
            guard let firstBundleType = ref.accumulatedBundles.first?.payload.type else {
                return (false, true)
            }
            
            if !ref.accumulatedBundles.contains(where: { $0.payload.type != firstBundleType }) {
                return (true, true)
            }
            else {
                return (false, false)
            }
        }
        
        if shouldBroadcast {
            broadcastAccumulatedPackages()
        }
        
        if shouldRecreateTimer {
            recreateRelatedPackagesTimer()
        }
    }
    
    private func relatedPackagesTimerDidFire(timer: Timer) {
        recreateUnrelatedPackagesTimer()
        broadcastAccumulatedPackages()
        
        state.async { ref in
            ref.isDefaultTimePeriodElapsed = false
        }
    }
    
    private func broadcastAccumulatedPackages() {
        let bundles: [NetworkingEventBundle] = state.sync { ref in
            let result = ref.accumulatedBundles
            ref.accumulatedBundles = []
            return result
        }
        
        if !bundles.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.signal.broadcast(bundles)
            }
        }
    }
}
