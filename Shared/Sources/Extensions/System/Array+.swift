//
//  ArrayExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 28/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

public extension Array {
    static var jv_empty: Self {
        return .init()
    }
    
    var jv_hasElements: Bool {
        return !isEmpty
    }
    
    var jv_hasOneElement: Bool {
        return (count == 1)
    }
}

public extension Sequence where Iterator.Element: JVOptionalType {
    func jv_flatten() -> [Iterator.Element.Wrapped] {
        return compactMap { $0.jv_optional }
    }
}

public extension Array where Element == String {
    func jv_stringOrEmpty(at index: Int) -> String {
        return (index < count ? self[index] : String())
    }
    
    func jv_markupMasked(_ isMasked: Bool) -> [Element] {
        if isMasked {
            return self
        }
        else {
            return map { $0
                .replacingOccurrences(of: "<mask>", with: "")
                .replacingOccurrences(of: "</mask>", with: "")
            }
        }
    }
}

public extension Array where Element: Equatable {
    func jv_unique() -> [Element] {
        var uniqueValues = [Element]()
        
        forEach { item in
            guard !uniqueValues.contains(item) else { return }
            uniqueValues.append(item)
        }
        
        return uniqueValues
    }
    
    func jv_doesNotContain(_ element: Element) -> Bool {
        return !contains(element)
    }
    
    mutating func jv_toggle(_ element: Element) {
        if let index = firstIndex(of: element) {
            remove(at: index)
        }
        else {
            append(element)
        }
    }
}

public extension Array where Element == Int {
    func jv_stringify() -> [String] {
        return map { String("\($0)") }
    }
}
