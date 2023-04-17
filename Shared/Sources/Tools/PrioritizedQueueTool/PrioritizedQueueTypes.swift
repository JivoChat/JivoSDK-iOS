//
// Created by Stan Potemkin on 2019-02-20.
// Copyright (c) 2019 JivoSite. All rights reserved.
//

import Foundation


struct PrioritizedQueuePriority: OptionSet, Hashable, Comparable {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }

    var hashValue: Int {
        return rawValue.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.hashValue)
    }

    static func <(lhs: PrioritizedQueuePriority, rhs: PrioritizedQueuePriority) -> Bool {
        guard lhs.rawValue < rhs.rawValue else { return false }
        return true
    }

    static func <=(lhs: PrioritizedQueuePriority, rhs: PrioritizedQueuePriority) -> Bool {
        guard lhs.rawValue <= rhs.rawValue else { return false }
        return true
    }

    static func >=(lhs: PrioritizedQueuePriority, rhs: PrioritizedQueuePriority) -> Bool {
        guard lhs.rawValue >= rhs.rawValue else { return false }
        return true
    }

    static func >(lhs: PrioritizedQueuePriority, rhs: PrioritizedQueuePriority) -> Bool {
        guard lhs.rawValue > rhs.rawValue else { return false }
        return true
    }
}

struct PrioritizedQueueItem<P: Equatable>: Equatable {
    let priority: PrioritizedQueuePriority
    let beginTime: Date
    let endTime: Date?
    let payload: P

    static func ==(lhs: PrioritizedQueueItem<P>, rhs: PrioritizedQueueItem<P>) -> Bool {
        guard lhs.priority == rhs.priority else { return false }
        guard lhs.beginTime == rhs.beginTime else { return false }
        guard lhs.endTime == rhs.endTime else { return false }
        guard lhs.payload == rhs.payload else { return false }
        return true
    }
    
    init(
        priority: PrioritizedQueuePriority,
        beginTime: Date,
        endTime: Date?,
        payload: P
    ) {
        self.priority = priority
        self.beginTime = beginTime
        self.endTime = endTime
        self.payload = payload
    }
}
