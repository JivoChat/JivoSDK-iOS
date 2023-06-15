//
//  ReachabilityDriverMock.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
@testable import Jivo

class ReachabilityDriverMock: IReachabilityDriver {
    var isReachable: Bool {
        fatalError()
    }
    
    var currentMode: ReachabilityMode {
        fatalError()
    }
    
    func start() {
        fatalError()
    }
    
    func addListener(block: @escaping (ReachabilityMode) -> Void) {
        fatalError()
    }
    
    func stop() {
        fatalError()
    }
}
