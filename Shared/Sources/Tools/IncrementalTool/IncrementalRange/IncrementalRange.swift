//
//  IncrementalRange.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation


protocol IIncrementalRange {
    func reachedLimit(value: Int) -> Bool
    func adjust(value: Int) -> Int
}
