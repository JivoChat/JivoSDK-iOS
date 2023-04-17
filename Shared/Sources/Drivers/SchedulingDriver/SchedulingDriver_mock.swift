//
//  SchedulingDriverMock.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
@testable import Jivo

class SchedulingDriverMock: ISchedulingDriver {
    func schedule(for ID: SchedulingActionID, delay: TimeInterval, repeats: Bool, block: @escaping SchedulingActionBlock) {
        fatalError()
    }
    
    func hasScheduled(for ID: SchedulingActionID) -> Bool {
        fatalError()
    }
    
    func fire(for ID: SchedulingActionID) {
        fatalError()
    }
    
    func kill(for ID: SchedulingActionID) -> Bool {
        fatalError()
    }
    
    func kill(prefix: SchedulingActionID) -> Int {
        fatalError()
    }
    
    func killAll() -> Int {
        fatalError()
    }
}
