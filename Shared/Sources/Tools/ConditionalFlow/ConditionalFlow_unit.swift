//
//  ConditionalFlowUnit.swift
//  TestFlow-Units
//
//  Created by Stan Potemkin on 01.11.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import XCTest
@testable import App

final class ConditionalFlowUnit: XCTestCase {
    private enum Value {
        case first
        case second
        case third
    }
    
    func test_initialValue() {
        let flow = ConditionalFlow<Value>(initialValue: .first)
        
        XCTAssertEqual(flow.currentValue, .first)
    }
    
    func test_turnTo() {
        let flow = ConditionalFlow<Value>(initialValue: .first)
        
        flow.turn(to: .second)
        
        XCTAssertEqual(flow.currentValue, .second)
    }
    
    func test_turnFromTo() {
        let flow = ConditionalFlow<Value>(initialValue: .first)
        
        flow.turn(to: .second)
        XCTAssertEqual(flow.currentValue, .second)
        
        flow.turn(from: .first, to: .third)
        XCTAssertEqual(flow.currentValue, .second)
        
        flow.turn(from: .second, to: .third)
        XCTAssertEqual(flow.currentValue, .third)
    }
    
    func test_equals() {
        let flow = ConditionalFlow<Value>(initialValue: .first)
        
        XCTAssert(flow.equals(value: .first))
        
        flow.turn(to: .second)
        XCTAssert(flow.equals(value: .second))
    }
    
    func test_reset() {
        let flow = ConditionalFlow<Value>(initialValue: .first)
        
        XCTAssertEqual(flow.currentValue, .first)
        flow.reset()
        XCTAssertEqual(flow.currentValue, .first)
        
        flow.turn(to: .second)
        XCTAssertEqual(flow.currentValue, .second)
        flow.reset()
        XCTAssertEqual(flow.currentValue, .first)
    }
}
