//
//  TimeoutBoxService.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/07/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

typealias SchedulingActionID = String
typealias SchedulingActionBlock = () -> Void

protocol ISchedulingDriver: AnyObject {
    func schedule(for ID: SchedulingActionID, delay: TimeInterval, repeats: Bool, block: @escaping SchedulingActionBlock)
    func hasScheduled(for ID: SchedulingActionID) -> Bool
    func fire(for ID: SchedulingActionID)
    
    @discardableResult
    func kill(for ID: SchedulingActionID) -> Bool
    
    func kill(prefix: SchedulingActionID) -> Int
    func killAll() -> Int
}

final class SchedulingDriver: ISchedulingDriver {
    private let core: ISchedulingCore

    private var timers = [SchedulingActionID: Timer]()

    init(core: ISchedulingCore) {
        self.core = core
    }
    
    func schedule(for ID: SchedulingActionID,
                  delay: TimeInterval,
                  repeats: Bool,
                  block: @escaping SchedulingActionBlock) {
        let sel = repeats ? #selector(handleRepeatedTimer) : #selector(handleOnceTimer)

        timers[ID].flatMap(core.untrigger)
        timers[ID] = core.trigger(delay: delay, target: self, sel: sel, userInfo: block, repeats: repeats)
    }
    
    func hasScheduled(for ID: SchedulingActionID) -> Bool {
        if let _ = timers[ID] {
            return true
        }
        else {
            return false
        }
    }
    
    func fire(for ID: SchedulingActionID) {
        guard let timer = timers.removeValue(forKey: ID) else { return }
        timer.fire()
    }
    
    func kill(for ID: SchedulingActionID) -> Bool {
        guard let timer = timers.removeValue(forKey: ID) else { return false }
        core.untrigger(timer: timer)
        removeTimer(timer)
        return true
    }

    func kill(prefix: SchedulingActionID) -> Int {
        let keys = timers.keys.filter { $0.hasPrefix(prefix) }
        keys.forEach { _ = kill(for: $0) }
        return keys.count
    }

    func killAll() -> Int {
        let num = timers.values.count
        timers.values.forEach(core.untrigger)
        timers.removeAll()
        return num
    }
    
    private func removeTimer(_ timer: Timer) {
        guard let item = timers.first(where: { $0.value === timer }) else { return }
        timers.removeValue(forKey: item.key)
    }
    
    @objc private func handleOnceTimer(_ timer: Timer) {
        let action = timer.userInfo as? SchedulingActionBlock
        defer { action?() }
        
        core.untrigger(timer: timer)
        removeTimer(timer)
    }
    
    @objc private func handleRepeatedTimer(_ timer: Timer) {
        let action = timer.userInfo as? SchedulingActionBlock
        action?()
    }
}
