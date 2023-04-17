//
//  JSONExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 05/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

public extension JsonElement {
    var status: JsonElement {
        return self
    }
    
    func has(key: String) -> JsonElement? {
        let value = self[key]
        return value.exists(withValue: false) ? value : nil
    }

    var stringToStringMap: [String: String]? {
        return ordict?.unOrderedMap.compactMapValues { $0.string }
    }

    var stringArray: [String] {
        return arrayValue.compactMap { $0.string }
    }

    var intArray: [Int]? {
        return array?.compactMap { $0.number?.intValue }
    }

    var valuable: String? {
        return stringValue.jv_valuable
    }
    
    func map<T>(_ block: (JsonElement) -> T) -> T? {
        if exists(withValue: true) {
            return block(self)
        }
        else {
            return nil
        }
    }
    
    func parse<T: JVDatabaseModelChange>(force: Bool = false) -> T? {
        if exists(withValue: true) {
            let change = T(json: self)
            return (change.isValid || force ? change : nil)
        }
        else {
            return nil
        }
    }
    
    func parseList<T: JVDatabaseModelChange>() -> [T]? {
        return array?.map { T(json: $0) }
    }
}

public func +(lhs: JsonElement, rhs: JsonElement) -> JsonElement {
    return lhs.merged(with: rhs)
}
