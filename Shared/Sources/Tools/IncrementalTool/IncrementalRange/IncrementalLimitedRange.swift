//
//  IncrementalLimitedRange.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation


struct IncrementalLimitedRange: IIncrementalRange {
    let limit: Int
    let loop: Bool

    func reachedLimit(value: Int) -> Bool {
        return (value == limit)
    }
    
    func adjust(value: Int) -> Int {
        guard value > limit else { return value }
        return loop ? 1 : limit
    }
}
