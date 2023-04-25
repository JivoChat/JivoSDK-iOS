//
// Created by Stan Potemkin on 2019-02-20.
// Copyright (c) 2019 JivoSite. All rights reserved.
//

import Foundation
import SwiftDate
import JivoFoundation


protocol IPrioritizedQueueTool: AnyObject {
    associatedtype Payload: Equatable
    var observable: JVBroadcastTool<PrioritizedQueueItem<Payload>?> { get }
    func schedule(item: PrioritizedQueueItem<Payload>)
    func discard(priority: PrioritizedQueuePriority)
    func discardAll()
    func findCurrentItem() -> PrioritizedQueueItem<Payload>?
}

class PrioritizedQueueTool<P: Equatable>: IPrioritizedQueueTool {
    let observable: JVBroadcastTool<PrioritizedQueueItem<P>?>

    private var items = [PrioritizedQueuePriority: PrioritizedQueueItem<P>]()
    private var lastItem: PrioritizedQueueItem<P>?
    private weak var updateTimer: Timer?

    init(observable: JVBroadcastTool<PrioritizedQueueItem<P>?>) {
        self.observable = observable
    }

    func schedule(item: PrioritizedQueueItem<P>) {
        items[item.priority] = item
        reschedule()
    }

    func discard(priority: PrioritizedQueuePriority) {
        items[priority] = nil
        reschedule()
    }

    func discardAll() {
        items.removeAll()
        reschedule()
    }

    func findCurrentItem() -> PrioritizedQueueItem<P>? {
        let now = Date()

        for priority in items.keys.sorted(by: >) {
            guard let item = items[priority] else { continue }
            guard now >= item.beginTime else { continue }

            if let endTime = item.endTime, now < endTime {
                return item
            }
            else if item.endTime == nil {
                return item
            }
        }

        return nil
    }

    private func cleanup() {
        let now = Date()
        for item in items.values {
            guard let endTime = item.endTime else { continue }
            guard endTime < now else { continue }
            items[item.priority] = nil
        }
    }

    private func reschedule() {
        broadcast()
        cleanup()

        if let time = findUpdateTime() {
            let interval = time.timeIntervalSince(Date())
            scheduleUpdate(seconds: interval)
        }
        else {
            cancelUpdateTimer()
        }
    }

    private func findUpdateTime() -> Date? {
        let now = Date()
        let futureItems = items.filter({ $0.value.beginTime > now })

        if let currentItem = findCurrentItem() {
            let upperItems = futureItems.filter({ $0.key > currentItem.priority }).map({ $0.value })
            let upperTime = upperItems.map({ $0.beginTime }).min()
            let lowerTime = currentItem.endTime

            if let upperTime = upperTime, let lowerTime = lowerTime {
                return upperTime.earlierDate(lowerTime)
            }
            else {
                return upperTime ?? lowerTime
            }
        }
        else {
            let futureTimes = futureItems.map({ $0.value.beginTime })
            return futureTimes.min()
        }
    }

    private func broadcast() {
        let item = findCurrentItem()
        guard item != lastItem else { return }
        
        lastItem = item
        observable.broadcast(item)
    }

    private func scheduleUpdate(seconds: TimeInterval) {
        cancelUpdateTimer()
        updateTimer = Timer.scheduledTimer(
            timeInterval: seconds,
            target: self,
            selector: #selector(handleUpdateTimer),
            userInfo: nil,
            repeats: false
        )
    }

    private func cancelUpdateTimer() {
        updateTimer?.invalidate()
    }

    @objc private func handleUpdateTimer() {
        reschedule()
    }
}
