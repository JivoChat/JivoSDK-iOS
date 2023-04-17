//
//  AccumulatorTool.swift
//  App
//
//  Created by Anton Karpushko on 16.09.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation

struct AccumulatorTool<ItemType> {
    private(set) var accumulatedItems = [ItemType]()
    
    init() {
    }
    
    mutating func accumulate(_ item: ItemType) {
        accumulatedItems.append(item)
    }
    
    mutating func accumulate(_ items: [ItemType]) {
        accumulatedItems.append(contentsOf: items)
    }
   
    @discardableResult
    internal mutating func release() -> [ItemType] {
        defer { accumulatedItems.removeAll() }
        return accumulatedItems
    }
}

class TimedAccumulatorTool<ItemType> {
    enum State {
        case waitingForFirstLaunch
        case working
        case paused
        case stoped
    }
    
    var releaseBlock: (([ItemType]) -> (Void))?
    var releaseTimeInterval: TimeInterval {
        didSet { releaseTimeIntervalChanged(to: releaseTimeInterval) }
    }
    var accumulatedItems: [ItemType] {
        return accumulator.accumulatedItems
    }
    
    private(set) var state = State.waitingForFirstLaunch
    
    private var accumulator: AccumulatorTool<ItemType>
    private var timer: DynamicTimer?
    
    private var timerTolerance: TimeInterval
    private var timerQueue: DispatchQueue
    
    init(accumulator: AccumulatorTool<ItemType>, releaseTimeInterval: TimeInterval, timerTolerance: TimeInterval, queue: DispatchQueue = .main, releaseBlock: (([ItemType]) -> (Void))? = nil) {
        self.accumulator = accumulator
        self.releaseTimeInterval = releaseTimeInterval
        self.timerTolerance = timerTolerance
        self.timerQueue = queue
        self.releaseBlock = releaseBlock
        
        scheduleTimer()
    }
    
    func accumulate(_ item: ItemType) {
        accumulator.accumulate(item)
    }
    
    func pause() {
        state = .paused
        timer?.pause()
    }
    
    func resume() {
        state = .working
        timer?.run()
    }
    
    func stop() {
        state = .stoped
        scheduleTimer()
    }
    
    internal func scheduleTimer() {
        timer = DynamicTimer(
            interval: releaseTimeInterval,
            repeats: true,
            tolerance: timerTolerance,
            queue: timerQueue
        ) { [weak self] _ in
            self?.release()
        }
    }
    
    internal func release() {
        let releasedItems = accumulator.release()
        releaseBlock?(releasedItems)
    }
    
    internal func removeAllAccumulatedItems() {
        accumulator.release()
    }
    
    internal func releaseTimeIntervalChanged(to newReleaseTimeInterval: TimeInterval) {
        timer?.setIntervalTo(newReleaseTimeInterval, applyingToCurrentCountdown: true)
    }
}
