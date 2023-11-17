//
//  Array+Ext.swift
//  App
//
//  Created by Yulia Popova on 22.11.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    mutating func jv_removeObject(_ object: AnyObject) where Element: AnyObject {
        removeAll(where: { $0 === object })
    }
}
