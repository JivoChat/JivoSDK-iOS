//
//  BoolExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 28/08/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

extension ClosedRange where Bound: Comparable {
    func jv_clamp(value: Bound) -> Bound {
        return Swift.max(lowerBound, Swift.min(upperBound, value))
    }
}
