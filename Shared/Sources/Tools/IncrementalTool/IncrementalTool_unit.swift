//
//  IncrementalToolUnit.swift
//  JivoMobile-Units
//
//  Created by Stan Potemkin on 08/12/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import XCTest
@testable import Jivo

final class IncrementalValueToolUnit: XCTestCase {
    func test_whenCallerAsksForNextValues_thenToolProvidesIncrementalValuesStarting1() {
        let storage = StorageMock()
        let tool = IncrementalTool(storage: .custom(storage), range: .unlimited)

        XCTAssertEqual(storage.value, 0)
        
        XCTAssertEqual(tool.next(), 1)
        XCTAssertEqual(storage.value, 1)
        
        XCTAssertEqual(tool.next(), 2)
        XCTAssertEqual(storage.value, 2)
    }
    
    func test_whenToolCreated_thenValueIsFirst() {
        let storage = StorageMock()
        let tool = IncrementalTool(storage: .custom(storage), range: .limited(2, loop: false))
        
        XCTAssertFalse(tool.reachedLimit)
    }

    func test_whenToolIncrementedOnce_thenValueIsMiddle() {
        let storage = StorageMock()
        let tool = IncrementalTool(storage: .custom(storage), range: .limited(2, loop: false))
        
        _ = tool.next()
        XCTAssertFalse(tool.reachedLimit)
    }

    func test_whenToolIncrementedTwice_thenValueIsLast() {
        let storage = StorageMock()
        let tool = IncrementalTool(storage: .custom(storage), range: .limited(2, loop: false))
        
        _ = tool.next()
        _ = tool.next()
        XCTAssertTrue(tool.reachedLimit)
    }

    func test_whenToolIncrementedOverLimit_thenValueIsLast() {
        let storage = StorageMock()
        let tool = IncrementalTool(storage: .custom(storage), range: .limited(2, loop: false))
        
        _ = tool.next()
        _ = tool.next()
        _ = tool.next()
        _ = tool.next()
        XCTAssertTrue(tool.reachedLimit)
    }

    func test_whenToolResetAfterIncrement_thenValueIsFirst() {
        let storage = StorageMock()
        let tool = IncrementalTool(storage: .custom(storage), range: .limited(2, loop: false))
        
        _ = tool.next()
        tool.reset()
        XCTAssertFalse(tool.reachedLimit)
    }
}

fileprivate final class StorageMock: IIncrementalStorage {
    var value = Int(0)
    var erased = false
    
    func erase() {
        erased = true
    }
}
