//
//  SchedulingDriverUnit.swift
//  JivoMobile-Units
//
//  Created by Stan Potemkin on 07/12/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import XCTest
@testable import Jivo

fileprivate let standardActionID = "action_id"
fileprivate let standardActionDelay = TimeInterval(2)
fileprivate let standardActionEmptyBlock = { () -> Void in }

final class SchedulingDriverUnit: XCTestCase {
    func test_whenToolShedulesAction_thenTimerShedulesEvaluation() {
        let core = SchedulingCoreMock()
        let tool = SchedulingDriver(core: core)
        let actionID = standardActionID
        
        XCTAssertFalse(tool.hasScheduled(for: actionID))
        XCTAssertNil(core.timer?.fireDate)
        
        tool.schedule(
            for: actionID,
            delay: standardActionDelay,
            repeats: false,
            block: { }
        )
        
        XCTAssertTrue(tool.hasScheduled(for: actionID))
        XCTAssertNotNil(core.timer?.fireDate)
        
        tool.kill(for: actionID)
        
        XCTAssertFalse(tool.hasScheduled(for: actionID))
        XCTAssertNil(core.timer?.fireDate)
    }
    
    func test_whenCallerAsksToSheduleAction_thenToolShedulesIt() {
        let core = SchedulingCoreMock()
        let tool = SchedulingDriver(core: core)
        let actionID = standardActionID
        
        XCTAssertFalse(tool.hasScheduled(for: actionID))
        
        tool.schedule(
            for: actionID,
            delay: standardActionDelay,
            repeats: false,
            block: { }
        )
        
        XCTAssertTrue(tool.hasScheduled(for: actionID))
    }
    
    func test_whenCallerAsksToKillAction_thenToolKillsIt() {
        let core = SchedulingCoreMock()
        let tool = SchedulingDriver(core: core)
        let actionID = standardActionID
        
        XCTAssertFalse(tool.hasScheduled(for: actionID))
        
        tool.schedule(
            for: actionID,
            delay: standardActionDelay,
            repeats: false,
            block: { }
        )
        
        XCTAssertTrue(tool.hasScheduled(for: actionID))
        
        tool.kill(for: actionID)
        
        XCTAssertFalse(tool.hasScheduled(for: actionID))
    }
    
    func test_whenCallerAsksToKillAllActions_thenToolKillsThemAll() {
        let core = SchedulingCoreMock()
        let tool = SchedulingDriver(core: core)
        let firstActionID = standardActionID + UUID().uuidString
        let secondActionID = standardActionID + UUID().uuidString
        
        XCTAssertFalse(tool.hasScheduled(for: firstActionID))
        XCTAssertFalse(tool.hasScheduled(for: secondActionID))
        
        tool.schedule(
            for: firstActionID,
            delay: standardActionDelay,
            repeats: false,
            block: { }
        )
        
        tool.schedule(
            for: secondActionID,
            delay: standardActionDelay,
            repeats: false,
            block: { }
        )
        
        XCTAssertTrue(tool.hasScheduled(for: firstActionID))
        XCTAssertTrue(tool.hasScheduled(for: secondActionID))
        
        tool.killAll()
        
        XCTAssertFalse(tool.hasScheduled(for: firstActionID))
        XCTAssertFalse(tool.hasScheduled(for: secondActionID))
    }
    
    func test_whenCallerAsksToFireAction_thenToolFiresIt() {
        let core = SchedulingCoreMock()
        let tool = SchedulingDriver(core: core)
        let actionID = standardActionID
        
        var flag = false
        tool.schedule(
            for: actionID,
            delay: standardActionDelay,
            repeats: false,
            block: { flag = true }
        )
        
        XCTAssertFalse(flag)
        
        tool.fire(for: actionID)
        
        XCTAssertTrue(flag)
    }
    
    func test_whenCallerSchedulesAction_thenToolShedulesItCorrectly() {
        let core = SchedulingCoreMock()
        let tool = SchedulingDriver(core: core)
        let actionID = standardActionID
        
        tool.schedule(
            for: actionID,
            delay: standardActionDelay,
            repeats: false,
            block: standardActionEmptyBlock
        )
        
        if let date = core.timer?.fireDate {
            let delay = date.timeIntervalSince(Date())
            XCTAssert(standardActionDelay - delay < 0.5)
        }
        else {
            XCTFail()
        }
    }
}

fileprivate final class SchedulingCoreMock: ISchedulingCore {
    var timer: Timer?
    
    func trigger(delay: TimeInterval, target: Any, sel: Selector, userInfo: Any?, repeats: Bool) -> Timer {
        let timer = Timer(timeInterval: delay, target: target, selector: sel, userInfo: userInfo, repeats: repeats)
        self.timer = timer
        
        return timer
    }
    
    func untrigger(timer: Timer) {
        timer.invalidate()
        self.timer = nil
    }
}
