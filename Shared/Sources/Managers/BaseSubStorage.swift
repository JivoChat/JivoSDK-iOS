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
    func reference<OT: JVDatabaseModel>(to object: OT?) -> JVDatabaseModelRef<OT>
    func reference<OT: JVDatabaseModel>(to objects: [OT]) -> [JVDatabaseModelRef<OT>]
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
    
    func reference<OT: JVDatabaseModel>(to object: OT?) -> JVDatabaseModelRef<OT> {
        return databaseDriver.reference(to: object)
    }
    
    func reference<OT: JVDatabaseModel>(to objects: [OT]) -> [JVDatabaseModelRef<OT>] {
        return objects.map(reference)
    }
}
