//
//  ComparableExtensions.swift
//  App
//
//  Created by Yulia Popova on 21.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension Comparable {
    func jv_clamp(_ from: Self, _ to: Self) -> Self {
        return min(max(self, from), to)
    }
}
