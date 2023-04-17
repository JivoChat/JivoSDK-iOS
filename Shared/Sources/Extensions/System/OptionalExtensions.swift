//
//  OptionalExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 15/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

public protocol JVOptionalType {
    associatedtype Wrapped
    var jv_optional: Wrapped? { get }
}

public extension Optional {
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
    public var jv_optional: Wrapped? {
        return self
    }

    mutating func jv_readAndReset() -> Wrapped? {
        defer { self = nil }
        return self
    }
}

/*
public extension Optional where Wrapped: Object {
    func jv_ifValid() -> Wrapped? {
        return self?.jv_ifValid()
    }
}
*/
