//
//  DynamicTimerTests.swift
//  DashaAppTests
//
//  Created by Anton Karpushko on 03.03.2021.
//

import XCTest
@testable import App

//class DynamicTimerUnit: XCTestCase {
//
//    var sut: DynamicTimer!
//    
//    override func tearDown() {
//        sut = nil
//    }
//    
//    func testNonRepeatingTimerFiring() {
//        // 1. Given
//        
//        let timerFirePromise = expectation(description: "nonRepeatingTimer1 fired")
//        
//        sut = DynamicTimer(interval: 2, repeats: false, tolerance: 0.5, queue: .main, uuid: "nonRepeatingTimer1") { timer in
//            timerFirePromise.fulfill()
//        }
//        
//        // 2. When
//        
//        sut.run()
//        
//        // 3. Then
//        
//        wait(for: [timerFirePromise], timeout: 2.6)
//    }
//    
//    func testNonRepeatingTimerRelaunch() {
//        // 1. Given
//        
//        let timerFirePromise = expectation(description: "nonRepeatingTimer2 fired")
//        var countOfFires = 0
//        
//        sut = DynamicTimer(interval: 2, repeats: false, tolerance: 0.5, queue: .main, uuid: "nonRepeatingTimer2") { timer in
//            countOfFires += 1
//            if countOfFires >= 2 {
//                timerFirePromise.fulfill()
//            }
//        }
//        
//        // 2. When
//        
//        sut.run()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            self.sut.run()
//        }
//        
//        // 3. Then
//        
//        wait(for: [timerFirePromise], timeout: 5.7)
//    }
//    
//    func testNonRepeatingTimerIntervalUpdateWithoutApplyingToCurrentCountdown() {
//        // 1. Given
//        
//        let timerFirePromise = expectation(description: "nonRepeatingTimer3 fired")
//        
//        sut = DynamicTimer(interval: 2, repeats: false, tolerance: 0.5, queue: .main, uuid: "nonRepeatingTimer3") { timer in
//            timerFirePromise.fulfill()
//        }
//        
//        // 2. When
//        
//        sut.run()
//        sut.setIntervalTo(100, applyingToCurrentCountdown: false)
//        
//        // 3. Then
//        
//        wait(for: [timerFirePromise], timeout: 2.6)
//    }
//    
//    func testNonRepeatingTimerIntervalUpdateWithApplyingToCurrentCountdownAndImmediateFire() {
//        // 1. Given
//        
//        let timerFirePromise = expectation(description: "nonRepeatingTimer4 fired")
//        var countOfFires = 0
//        
//        sut = DynamicTimer(interval: 8, repeats: false, tolerance: 0.5, queue: .main, uuid: "nonRepeatingTimer4") { timer in
//            countOfFires += 1
//            if countOfFires >= 2 {
//                timerFirePromise.fulfill()
//            }
//        }
//        
//        // 2. When
//        
//        sut.run()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
//            self.sut.setIntervalTo(1, applyingToCurrentCountdown: true)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [self] in
//            self.sut.run()
//        }
//        
//        // 3. Then
//        
//        wait(for: [timerFirePromise], timeout: 4.2)
//    }
//    
//    func testNonRepeatingTimerIntervalUpdateWithApplyingToCurrentCountdownAndProlongedFire() {
//        // 1. Given
//        
//        let timerFirePromise = expectation(description: "nonRepeatingTimer5 fired")
//        var countOfFires = 0
//        
//        sut = DynamicTimer(interval: 18, repeats: false, tolerance: 0.5, queue: .main, uuid: "nonRepeatingTimer5") { timer in
//            countOfFires += 1
//            if countOfFires >= 2 {
//                timerFirePromise.fulfill()
//            }
//        }
//        
//        // 2. When
//        
//        sut.run()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
//            self.sut.setIntervalTo(4, applyingToCurrentCountdown: true)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 4.6) { [self] in
//            self.sut.run()
//        }
//        
//        // 3. Then
//        
//        wait(for: [timerFirePromise], timeout: 9.1)
//    }
//    
//    func testRepeatingTimerFiring() {
//        // 1. Given
//        
//        let timerFirstLoopFirePromise = expectation(description: "repeatingTimer1 fired for the first time")
//        let timerSecondLoopFirePromise = expectation(description: "repeatingTimer1 fired for the second time")
//        let timerthirdLoopFirePromise = expectation(description: "repeatingTimer1 fired for the third time")
//        var countOfFires = 0
//        
//        sut = DynamicTimer(interval: 1, repeats: true, tolerance: 0.1, queue: .main, uuid: "repeatingTimer1") { timer in
//            countOfFires += 1
//            switch countOfFires {
//            case 1: timerFirstLoopFirePromise.fulfill()
//            case 2: timerSecondLoopFirePromise.fulfill()
//            case 3: timerthirdLoopFirePromise.fulfill()
//            default: break
//            }
//        }
//        
//        // 2. When
//        
//        sut.run()
//        
//        // 3. Then
//        
//        wait(for: [timerFirstLoopFirePromise, timerSecondLoopFirePromise, timerthirdLoopFirePromise], timeout: 3.5)
//    }
//    
//    func testRepeatingTimerIntervalUpdateWithoutApplyingToCurrentCountdownThenResetAndRun() {
//        // 1. Given
//        
//        let timerFirstLoopFirePromise = expectation(description: "repeatingTimer1 fired for the first time")
//        let timerSecondLoopFirePromise = expectation(description: "repeatingTimer1 fired for the second time")
//        let timerthirdLoopFirePromise = expectation(description: "repeatingTimer1 fired for the third time")
//        let timerFourthLoopFirePromise = expectation(description: "repeatingTimer1 fired for the fourth time")
//        let timerFifthLoopFirePromise = expectation(description: "repeatingTimer1 fired for the fifth time")
//        var countOfFires = 0
//        
//        sut = DynamicTimer(interval: 4, repeats: true, tolerance: 0.1, queue: .main, uuid: "repeatingTimer1") { timer in
//            countOfFires += 1
//            switch countOfFires {
//            case 1: timerFirstLoopFirePromise.fulfill()
//            case 2: timerSecondLoopFirePromise.fulfill()
//            case 3: timerthirdLoopFirePromise.fulfill()
//            case 4: timerFourthLoopFirePromise.fulfill()
//            case 5:
//                timerFifthLoopFirePromise.fulfill()
//                self.sut.reset()
//            default: break
//            }
//        }
//        
//        // 2. When
//        
//        sut.run()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 4.6) {
//            self.sut.setIntervalTo(1, applyingToCurrentCountdown: false)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 9.4) {
//            self.sut.setIntervalTo(1, applyingToCurrentCountdown: true)
//            self.sut.run()
//        }
//        
//        // 3. Then
//        
//        wait(
//            for: [
//                timerFirstLoopFirePromise,
//                timerSecondLoopFirePromise,
//                timerthirdLoopFirePromise,
//                timerFourthLoopFirePromise,
//                timerFifthLoopFirePromise
//            ],
//            timeout: 11.7
//        )
//    }
//    
//    func testRepeatingTimerIntervalUpdateWithApplyingToCurrentCountdownAndImmediateFire() {
//        // 1. Given
//        
//        let timerFirstLoopFirePromise = expectation(description: "repeatingTimer2 fired for the first time")
//        let timerSecondLoopFirePromise = expectation(description: "repeatingTimer2 fired for the second time")
//        let timerthirdLoopFirePromise = expectation(description: "repeatingTimer2 fired for the third time")
//        let timerFourthLoopFirePromise = expectation(description: "repeatingTimer2 fired for the fourth time")
//        let timerFifthLoopFirePromise = expectation(description: "repeatingTimer2 fired for the fifth time")
//        var countOfFires = 0
//        
//        sut = DynamicTimer(interval: 4, repeats: true, tolerance: 0.1, queue: .main, uuid: "repeatingTimer2") { timer in
//            countOfFires += 1
//            switch countOfFires {
//            case 1: timerFirstLoopFirePromise.fulfill()
//            case 2: timerSecondLoopFirePromise.fulfill()
//            case 3: timerthirdLoopFirePromise.fulfill()
//            case 4: timerFourthLoopFirePromise.fulfill()
//            case 5: timerFifthLoopFirePromise.fulfill()
//            default: break
//            }
//        }
//        
//        // 2. When
//        
//        sut.run()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.sut.setIntervalTo(1, applyingToCurrentCountdown: true)
//        }
//        
//        // 3. Then
//        
//        wait(
//            for: [
//                timerFirstLoopFirePromise,
//                timerSecondLoopFirePromise,
//                timerthirdLoopFirePromise,
//                timerFourthLoopFirePromise,
//                timerFifthLoopFirePromise
//            ],
//            timeout: 6.5
//        )
//    }
//    
//    func testRepeatingTimerIntervalUpdateWithApplyingToCurrentCountdownAndProlongedFire() {
//        // 1. Given
//        
//        let timerFirstLoopFirePromise = expectation(description: "repeatingTimer3 fired for the first time")
//        let timerSecondLoopFirePromise = expectation(description: "repeatingTimer3 fired for the second time")
////        let timerthirdLoopFirePromise = expectation(description: "repeatingTimer3 fired for the third time")
////        let timerFourthLoopFirePromise = expectation(description: "repeatingTimer3 fired for the fourth time")
////        let timerFifthLoopFirePromise = expectation(description: "repeatingTimer3 fired for the fifth time")
//        var countOfFires = 0
//        
//        sut = DynamicTimer(interval: 2, repeats: true, tolerance: 0.1, queue: .main, uuid: "repeatingTimer3") { timer in
//            countOfFires += 1
//            switch countOfFires {
//            case 1: timerFirstLoopFirePromise.fulfill()
//            case 2: timerSecondLoopFirePromise.fulfill()
////            case 3: timerthirdLoopFirePromise.fulfill()
////            case 4: timerFourthLoopFirePromise.fulfill()
////            case 5: timerFifthLoopFirePromise.fulfill()
//            default: break
//            }
//        }
//        
//        // 2. When
//        
//        sut.run()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            self.sut.setIntervalTo(5, applyingToCurrentCountdown: true)
//        }
//        
//        // 3. Then
//        
//        wait(
//            for: [
//                timerFirstLoopFirePromise,
//                timerSecondLoopFirePromise
////                timerthirdLoopFirePromise,
////                timerFourthLoopFirePromise,
////                timerFifthLoopFirePromise
//            ],
//            timeout: 10.3
//        )
//    }
//}
