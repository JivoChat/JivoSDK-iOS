//
//  FileManager+Extensions.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 19.02.2023.
//

import Foundation
import JMCodingKit

extension JsonElement {
    init<T>(key: String, value: T?) {
        if let value = value {
            self.init([key: value])
        } else {
            self.init(Dictionary<String, T>())
        }
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
}

func +(lhs: JsonElement, rhs: JsonElement) -> JsonElement {
    return lhs.merged(with: rhs)
}
