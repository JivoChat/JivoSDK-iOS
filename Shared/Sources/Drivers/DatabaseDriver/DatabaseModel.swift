//
//  CoreDataModel.swift
//  App
//
//  Created by Stan Potemkin on 21.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import CoreData

@objc(JVDatabaseModel)
class JVDatabaseModel: NSManagedObject {
    @NSManaged var m_uid: String?
    @NSManaged var m_pk_num: Int64
    @NSManaged var m_pk_str: String?
    private var cache = [String: Any]()

    open override func awakeFromInsert() {
        super.awakeFromInsert()
        m_uid = UUID().uuidString.lowercased()
    }
    
    open func apply(context: JVIDatabaseContext, change: JVDatabaseModelChange) {
    }
    
    func takeFromCache<T>(key: String, defaultValue: T) -> T {
        return cache[key] as! T
    }
    
    func putIntoCache<T>(key: String, value: T) {
        cache[key] = value
    }
}

public struct JVMetaProviders {
    let clientProvider: (Int) -> JVClient?
}
