//
//  ListExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 11/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

/*
public extension List {
    func jv_toArray() -> [Element] {
        return Array(self)
    }
    
    func jv_set(_ items: [Element]) {
        removeAll()
        append(objectsIn: items)
    }
}

public extension List where Element: JVBaseModel {
    func jv_insertAbsent(_ items: [Element]) {
        guard let primaryKey = Element.primaryKey() else { return }
        
        let currentIDs = map { item in
            return item.value(forKey: primaryKey) as! Int
        }
        
        let absentItems = items.filter { item in
            let itemID = item.value(forKey: primaryKey) as! Int
            return !currentIDs.contains(itemID)
        }
        
        append(objectsIn: absentItems)
    }
}
*/