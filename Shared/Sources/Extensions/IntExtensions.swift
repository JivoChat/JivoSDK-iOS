//
//  IntExtensions.swift
//  App
//
//  Created by Stan Potemkin on 03.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension Int {
    var jv_valuable: Int? {
        return (self == 0 ? nil : self)
    }
}
