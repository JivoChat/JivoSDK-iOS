//
//  IncrementalUnlimitedRange.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation


struct IncrementalUnlimitedRange: IIncrementalRange {
    func reachedLimit(value: Int) -> Bool {
        return false
    }
    
    func adjust(value: Int) -> Int {
        return value
    }
}
