//
//  DatabaseModelRef.swift
//  App
//
//  Created by Stan Potemkin on 20.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import CoreData

public final class JVDatabaseModelRef<Value: JVDatabaseModel> {
    private weak var coreDataDriver: JVIDatabaseDriver?
    let objectId: NSManagedObjectID?
    
    public init(coreDataDriver: JVIDatabaseDriver, value: Value?) {
        self.coreDataDriver = coreDataDriver
        self.objectId = value?.objectID
    }
    
    public var resolved: Value? {
        return resolve()
    }
    
    public func resolve() -> Value? {
        guard let objectId = objectId else {
            return nil
        }
        
        let object = coreDataDriver?.object(Value.self, internalId: objectId)
        return object
    }
}
