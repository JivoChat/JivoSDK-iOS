//
//  DatabaseEntityRef.swift
//  App
//
//  Created by Stan Potemkin on 20.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import CoreData

final class DatabaseEntityRef<Value: DatabaseEntity> {
    private weak var coreDataDriver: JVIDatabaseDriver?
    let objectId: NSManagedObjectID?
    
    init(coreDataDriver: JVIDatabaseDriver, value: Value?) {
        self.coreDataDriver = coreDataDriver
        
        if let value = value {
            if value.objectID.isTemporaryID {
                try? value.managedObjectContext?.obtainPermanentIDs(for: [value])
            }
            
            self.objectId = value.objectID
        }
        else {
            self.objectId = nil
        }
    }
    
    var resolved: Value? {
        return resolve()
    }
    
    func resolve() -> Value? {
        guard let objectId = objectId else {
            return nil
        }
        
        let object = coreDataDriver?.object(Value.self, internalId: objectId)
        return object
    }
}
