//
//  SetExtensions.swift
//  App
//
//  Created by Stan Potemkin on 22.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

public extension Optional where Wrapped == NSSet {
    var jv_orEmpty: NSSet {
        return self ?? NSSet()
    }
}
