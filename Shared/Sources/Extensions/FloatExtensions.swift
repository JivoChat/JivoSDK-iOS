//
//  FloatExtensions.swift
//  App
//
//  Created by Yulia Popova on 21.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension Float {
    func jv_clamp(_ from: Float, _ to: Float) -> Float {
        return min(max(self, from), to)
    }
}
