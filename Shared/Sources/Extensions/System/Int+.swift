//
//  IntExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 12/10/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation

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
    
    var jv_toInt16: Int16 {
        return Int16(self)
    }
    
    var jv_toInt32: Int32 {
        return Int32(self)
    }
    
    var jv_toInt64: Int64 {
        return Int64(self)
    }
}
