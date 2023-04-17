//
//  BoolExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 28/08/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

public extension ClosedRange where Bound: Comparable {
    func jv_clamp(value: Bound) -> Bound {
        return max(lowerBound, min(upperBound, value))
    }
}
