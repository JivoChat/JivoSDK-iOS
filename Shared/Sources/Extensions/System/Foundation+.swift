//
//  FoundationExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 21/03/2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation

func jv_convert<Source, Target>(_ value: Source, block: (Source) -> Target) -> Target {
    return block(value)
}

func not(_ value: Bool) -> Bool {
    return jv_not(value)
}

func jv_not(_ value: Bool) -> Bool {
    return !value
}

func jv_with<T, R>(_ value: @autoclosure () -> T, block: (inout T) -> R) -> R {
    var localValue = value()
    return block(&localValue)
}

func jv_evaluate<Value>(block: () -> Value) -> Value {
    return block()
}
