//
//  UUIDExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 09/11/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

public extension UUID {
    var jv_shortString: String {
        return String(uuidString.lowercased().prefix(6))
    }
}
