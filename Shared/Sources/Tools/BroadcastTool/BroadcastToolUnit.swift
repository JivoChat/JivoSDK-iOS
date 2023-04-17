//
//  BroadcastToolUnit.swift
//  JivoMobile-Units
//
//  Created by Stan Potemkin on 07/12/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import XCTest
@testable import JivoSDKDemo

public final class BroadcastToolUnit: XCTestCase {
    public func test_whenObserverDelinked_thenObserverUnsubscribes() {
        let observable = BroadcastTool<Bool>()
        var observer: BroadcastObserver<Bool>?
        
        var counter = 0
        observer = observable.addObserver { _ in counter += 1 }
        
        XCTAssertEqual(counter, 0)
        
        observable.broadcast(true)
        
        XCTAssertEqual(counter, 1)
        
        observer = nil
        observable.broadcast(true)
        
        XCTAssertEqual(counter, 1)
    }
    
    public func test_whenObservableBroadcastsValue_thenObserverCatchesIt() {
        let observable = BroadcastTool<Int?>()
        var observer: BroadcastObserver<Int?>?
        
        var lastValue: Int?
        observer = observable.addObserver { value in lastValue = value }
        
        XCTAssertEqual(lastValue, nil)
        
        observable.broadcast(0)
        
        XCTAssertEqual(lastValue, 0)
        
        observable.broadcast(5)
        
        XCTAssertEqual(lastValue, 5)
        
        observable.broadcast(nil)
        
        XCTAssertEqual(lastValue, nil)
    }
}
