//
//  OptionalExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 15/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

protocol JVOptionalType {
    associatedtype Wrapped
    var jv_optional: Wrapped? { get }
}

extension Optional {
    var jv_hasValue: Bool {
        if let _ = self {
            return true
        }
        else {
            return false
        }
    }
}

extension Optional: JVOptionalType {
    var jv_optional: Wrapped? {
        return self
    }

    mutating func jv_readAndReset() -> Wrapped? {
        defer { self = nil }
        return self
    }
}

extension Optional where Wrapped: Comparable {
    mutating func jv_replaceWithGreater(_ another: Wrapped) {
        if let value = self {
            self = max(value, another)
        }
        else {
            self = another
        }
    }
    
    mutating func jv_replaceWithLesser(_ another: Wrapped) {
        if let value = self {
            self = min(value, another)
        }
        else {
            self = another
        }
    }
}
