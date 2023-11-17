//
//  IntExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 12/10/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation

enum JVIntConversionBehavior {
    case standard
    case clamping
}

extension Int {
    var jv_valuable: Int? {
        return (self == 0 ? nil : self)
    }

    func jv_hasBit(_ flag: Int) -> Bool {
        return ((self & flag) > 0)
    }

    func jv_toString() -> String {
        return "\(self)"
    }
    
    func jv_toInt16(_ behavior: JVIntConversionBehavior) -> Int16 {
        switch behavior {
        case .standard:
            return Int16(self)
        case .clamping:
            return Int16(clamping: self)
        }
    }
    
    func jv_toInt32(_ behavior: JVIntConversionBehavior) -> Int32 {
        switch behavior {
        case .standard:
            return Int32(self)
        case .clamping:
            return Int32(clamping: self)
        }
    }
    
    func jv_toInt64(_ behavior: JVIntConversionBehavior) -> Int64 {
        switch behavior {
        case .standard:
            return Int64(self)
        case .clamping:
            return Int64(clamping: self)
        }
    }
    
    mutating func jv_increment() -> Int {
        self += 1
        return self
    }
    
    mutating func jv_decrement() -> Int {
        self -= 1
        return self
    }
}
