//
//  BaseSubStorage.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 16.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation


protocol IBaseSubStorage: AnyObject {
    func refresh()
    func reference<OT: DatabaseEntity>(to object: OT?) -> DatabaseEntityRef<OT>
    func reference<OT: DatabaseEntity>(to objects: [OT]) -> [DatabaseEntityRef<OT>]
}

class BaseSubStorage: IBaseSubStorage {
    let userContextAny: AnyObject
    let databaseDriver: JVIDatabaseDriver
    
    init(userContext: AnyObject, databaseDriver: JVIDatabaseDriver) {
        self.userContextAny = userContext
        self.databaseDriver = databaseDriver
    }
    
    func refresh() {
        _ = databaseDriver.refresh()
    }
    
    func reference<OT: DatabaseEntity>(to object: OT?) -> DatabaseEntityRef<OT> {
        return databaseDriver.reference(to: object)
    }
    
    func reference<OT: DatabaseEntity>(to objects: [OT]) -> [DatabaseEntityRef<OT>] {
        return objects.map(reference)
    }
}
