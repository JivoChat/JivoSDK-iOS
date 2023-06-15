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
    
    private var unrelatedPackagesTimer: Timer?
    private var relatedPackagesTimer: Timer?
    
    // Internal state
    
    private var isTimersStarted = false
    private var isDefaultTimePeriodElapsed = false
    
    private var accumulatedBundles: [NetworkingEventBundle] = []
    
    // MARK: - Init/deinit
    
    init(defaultTimeInterval: TimeInterval, prolongedTimeInterval: TimeInterval, timersTolerance: TimeInterval = 0) {
        self.defaultTimeInterval = defaultTimeInterval
        self.prolongedTimeInterval = prolongedTimeInterval
        self.timersTolerance = timersTolerance
    }
    
    deinit {
        invalidateTimers()
    }
    
    // MARK: - Public methods
    
    func take(_ bundle: NetworkingEventBundle) {
        accumulatedBundles.append(bundle)
        
        if !(isTimersStarted) {
            initializeTimers()
        }
    }
    
    // MARK: - Private methods
    
    private func initializeTimers() {
        invalidateTimers()
        
        recreateUnrelatedPackagesTimer()
        recreateRelatedPackagesTimer()
        
        isTimersStarted = true
    }
    
    private func invalidateTimers() {
        unrelatedPackagesTimer?.invalidate()
        relatedPackagesTimer?.invalidate()
        
        unrelatedPackagesTimer = nil
        relatedPackagesTimer = nil
        
        isTimersStarted = false
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
        defer {
            isDefaultTimePeriodElapsed = true
        }
        
        guard let firstBundleType = accumulatedBundles.first?.payload.type else {
            recreateRelatedPackagesTimer()
            return
        }
        
        if accumulatedBundles.first(where: { $0.payload.type != firstBundleType }) == nil {
            broadcastAccumulatedPackages()
            recreateRelatedPackagesTimer()
        }
    }
    
    private func relatedPackagesTimerDidFire(timer: Timer) {
        recreateUnrelatedPackagesTimer()
        broadcastAccumulatedPackages()
        
        isDefaultTimePeriodElapsed = false
    }
    
    private func broadcastAccumulatedPackages() {
        signal.broadcast(accumulatedBundles)
        accumulatedBundles = []
    }
}
