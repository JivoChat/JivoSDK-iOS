//
//  FormatterExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 09.09.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation

public extension Formatter {
    func jv_format(_ obj: Any?) -> String {
        return string(for: obj) ?? String(describing: obj)
    }
}
