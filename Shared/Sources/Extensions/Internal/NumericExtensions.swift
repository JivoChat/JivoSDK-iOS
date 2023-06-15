//
//  NumericExtensions.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 15.01.2023.
//

import Foundation

extension Optional where Wrapped: Numeric {
    var jv_orZero: Wrapped {
        switch self {
        case .some(let value):
            return value
        case .none:
            return .zero
        }
    }
}
