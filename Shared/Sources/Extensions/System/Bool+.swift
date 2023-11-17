//
//  BoolExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 28/08/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

extension Bool {
    func jv_inverted() -> Bool {
        return !self
    }
    
    func jv_int() -> Int {
        return self ? 1 : 0
    }
    
    func jv_string() -> String {
        return self ? "true" : "false"
    }
}
