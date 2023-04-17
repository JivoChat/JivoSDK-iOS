//
//  DynamicTimer.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 11.03.2021.
//

import Foundation

enum DynamicallyTimingState {
    case idle
    case running
    case paused
}

protocol DynamicallyTiming {
    var state: DynamicallyTimingState { get }
    var interval: TimeInterval { get }
    var repeats: Bool { get set }
    var tolerance: TimeInterval { get set }
    var uuid: String { get }
    
    func run()
    func pause()
    func reset()
    func setIntervalTo(_ newInterval: TimeInterval, applyingToCurrentCountdown: Bool)
}

class DynamicTimer: DynamicallyTiming {
    typealias FireBlock = (DynamicTimer) -> Void
    
    var state: DynamicallyTimingState = .idle
    var interval: TimeInterval
    var repeats: Bool
    var tolerance: TimeInterval
    let uuid: String
    
    private var internalState: DynamicTimerState?
    private var isInvalidationOnFireNeeded = false {
        didSet {
//            print("DynamicTimer with UUID: \(uuid) – isInvalidationOnFireNeeded new value is \(isInvalidationOnFireNeeded)")
        }
    }
    private var startDate = Date()
    private var timer: DispatchSourceTimer?
    
    private let queue: DispatchQueue
    private let fireBlock: FireBlock
    
    init(
        interval: TimeInterval,
        repeats: Bool,
        tolerance: TimeInterval,
        queue: DispatchQueue = .main,
        uuid: String = "",
        fireBlock: @escaping FireBlock
    ) {
        self.interval = interval
        self.repeats = repeats
        self.tolerance = tolerance
        self.queue = queue
        self.uuid = uuid
        self.fireBlock = fireBlock
        
        queue.async {
            self.internalState = IdleState(context: self)
        }
    }
    
    func run() {
        queue.async {
            self.internalState?.run()
        }
    }
    
    func pause() {
        queue.async {
            self.internalState?.pause()
        }
    }
    
    func reset() {
//        print("DynamicTimer with UUID: \(uuid) – reset() method was called.")
        
        queue.async {
            self.internalState = IdleState(context: self)
        }
    }
    
    func setIntervalTo(_ newInterval: TimeInterval, applyingToCurrentCountdown: Bool) {
//        print("DynamicTimer with UUID: \(uuid) – setInterval(to: \(newInterval)), lastState: \(state), applyingToCurrentCountdown: \(applyingToCurrentCountdown), isInvalidationOnFireNeeded: \(!applyingToCurrentCountdown)")
        
        queue.async {
            self.interval = newInterval
            self.isInvalidationOnFireNeeded = !applyingToCurrentCountdown
            self.internalState?.setIntervalTo(newInterval, applyingToCurrentCountdown: applyingToCurrentCountdown)
        }
    }
    
    private func timerFired() {
//        print("DynamicTimer with UUID: \(uuid) – FIRED! isInvalidationOnFireNeeded: \(isInvalidationOnFireNeeded), interval: \(interval)")
        
        fireBlock(self)
        
        startDate = Date()
        
        if isInvalidationOnFireNeeded || !repeats {
            reset()
        }
        
        if isInvalidationOnFireNeeded {
            isInvalidationOnFireNeeded = false
            
            if repeats {
                run()
            }
        }
    }
    
    private func makeTimer() -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(
            flags: DispatchSource.TimerFlags(rawValue: 0),
            queue: queue
        )
        return timer
    }
    
    private func setupTimer(withFirstCountdownInterval firstCountdownInterval: TimeInterval? = nil) {
//        print("DynamicTimer with UUID: \(uuid) – setupTimer(withFirstCountdownInterval: \(String(describing: firstCountdownInterval))), interval: \(interval)")
        
        timer?.cancel()
//        print("DynamicTimer with UUID: \(uuid) – timer canceled")
        timer = makeTimer()
//        print("DynamicTimer with UUID: \(uuid) – timer was created")
        
        let firstCountdownIntervalInMilliseconds = DispatchTimeInterval.milliseconds(milliseconds(from: firstCountdownInterval ?? interval))
        let intervalInMilliseconds = DispatchTimeInterval.milliseconds(milliseconds(from: interval))
        
        timer?.schedule(
            deadline: .now() + firstCountdownIntervalInMilliseconds,
            repeating: repeats
                ? intervalInMilliseconds
                : DispatchTimeInterval.never,
            leeway: DispatchTimeInterval.seconds(milliseconds(from: tolerance))
        )
        
//        print("DynamicTimer with UUID: \(uuid) – timer scheduled")
        
        timer?.setEventHandler { [weak self] in
            self?.timerFired()
        }
        
//        print("DynamicTimer with UUID: \(uuid) – timer event handler set")
    }
    
    private func milliseconds(from interval: TimeInterval) -> Int {
        return Int(interval * 1000)
    }
}

protocol DynamicTimerState {
    var context: DynamicTimer? { get }
    
    func run()
    func pause()
    func setIntervalTo(_ newInterval: TimeInterval, applyingToCurrentCountdown: Bool)
}

extension DynamicTimer {
    struct IdleState: DynamicTimerState {
        weak var context: DynamicTimer?
        
        init(context: DynamicTimer) {
//            print("DynamicTimer with UUID: \(context.uuid) – has performed transition to idle state.")
            
            self.context = context
            
            context.setupTimer()
            context.state = .idle
        }
        
        func run() {
            context?.internalState = context.flatMap(RunningState.init(context:))
        }
        
        func pause() {
//            print("DynamicTimer with UUID: \(context?.uuid ?? "[nil]") – no action was performed on pause() method call because the timer is in idle state.")
        }
        
        func setIntervalTo(_ newInterval: TimeInterval, applyingToCurrentCountdown: Bool) {
            context?.setupTimer()
        }
    }
    
    struct RunningState: DynamicTimerState {
        weak var context: DynamicTimer?
        
        init(context: DynamicTimer) {
//            print("DynamicTimer with UUID: \(context.uuid) – has performed transition to running state.")
            
            self.context = context
            
            context.timer?.resume()
            context.state = .running
        }
        
        func run() {
//            print("DynamicTimer with UUID: \(context?.uuid ?? "[nil]") – no action was performed on run() method call because the timer is already in running state.")
        }
        
        func pause() {
            context?.internalState = context.flatMap(RunningState.init(context:))
        }
        
        func setIntervalTo(_ newInterval: TimeInterval, applyingToCurrentCountdown: Bool) {
            if let startDate = context?.startDate, applyingToCurrentCountdown {
                let currentDate = Date()
                
                if currentDate.timeIntervalSince(startDate) >= newInterval {
//                    print("DynamicTimer with UUID: \(context?.uuid ?? "[nil]") – new interval is smaller than the time interval since start date, isInvalidationOnFireNeeded: true")
                    
                    context?.isInvalidationOnFireNeeded = true
                    context?.timerFired()
                } else {
                    let nextFireDate = context?.startDate.addingTimeInterval(newInterval)
                    let timeIntervalBeforeFiring = nextFireDate?.timeIntervalSince(currentDate)
                    
//                    print("DynamicTimer with UUID: \(context?.uuid ?? "[nil]") – new interval is larger than the time interval since start date, isInvalidationOnFireNeeded: false, timeIntervalBeforeFiring: \(timeIntervalBeforeFiring)")
                    
                    context?.setupTimer(withFirstCountdownInterval: timeIntervalBeforeFiring)
                    context?.timer?.resume()
                }
            }
        }
    }
    
    struct PausedState: DynamicTimerState {
        weak var context: DynamicTimer?
        
        init(context: DynamicTimer) {
//            print("DynamicTimer with UUID: \(context.uuid) – has performed transition to paused state.")
            
            self.context = context
            
            context.timer?.suspend()
            context.state = .paused
        }
        
        func run() {
            context?.internalState = context.flatMap(RunningState.init(context:))
        }
        
        func pause() {
//            print("DynamicTimer with UUID: \(context?.uuid ?? "[nil]") – no action was performed on pause() method call because the timer is already in paused state.")
        }
        
        func setIntervalTo(_ newInterval: TimeInterval, applyingToCurrentCountdown: Bool) {}
    }
}
