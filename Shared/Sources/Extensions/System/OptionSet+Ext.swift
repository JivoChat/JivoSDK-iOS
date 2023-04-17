//
//  OptionSet+Ext.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 03.03.2023.
//

import Foundation

public extension OptionSet where RawValue: BinaryInteger {
    public static var jv_empty: Self {
        return .init(rawValue: 0)
    }
}

public func +<Options: OptionSet>(lhs: Options, rhs: Options) -> Options {
    return lhs.union(rhs)
}
