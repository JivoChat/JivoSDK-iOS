//
//  FoundationExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 21/03/2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation

public func jv_convert<Source, Target>(_ value: Source, block: (Source) -> Target) -> Target {
    return block(value)
}

public func jv_not(_ value: Bool) -> Bool {
    return !value
}

public func jv_with<T, R>(_ value: @autoclosure () -> T, block: (inout T) -> R) -> R {
    var localValue = value()
    return block(&localValue)
}

public func jv_evaluate<Value>(block: () -> Value) -> Value {
    return block()
}
