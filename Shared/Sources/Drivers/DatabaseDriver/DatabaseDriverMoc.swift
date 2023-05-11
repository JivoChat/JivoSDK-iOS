//
//  DatabaseDriverMoc.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 09.04.2023.
//

import Foundation
import CoreData

final class JVDatabaseDriverMoc: NSManagedObjectContext {
    let namespace: String
    
    init(namespace: String, concurrencyType ct: NSManagedObjectContextConcurrencyType) {
        self.namespace = namespace
        
        super.init(concurrencyType: ct)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
