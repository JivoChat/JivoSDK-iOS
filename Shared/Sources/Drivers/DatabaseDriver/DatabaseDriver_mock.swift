//
//  DatabaseDriverMock.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 08.03.2023.
//

import Foundation
import CoreData

class JVDatabaseDriverMock: JVIDatabaseDriver {
    func refresh() -> JVIDatabaseDriver {
        fatalError()
    }

    func reference<OT: JVDatabaseModel>(to object: OT?) -> JVDatabaseModelRef<OT> {
        fatalError()
    }
    
    func resolve<OT: JVDatabaseModel>(ref: JVDatabaseModelRef<OT>) -> OT? {
        fatalError()
    }
    
    func read(_ block: (JVIDatabaseContext) -> Void) {
        fatalError()
    }
    
    func readwrite(_ block: (JVIDatabaseContext) -> Void) {
        fatalError()
    }

    func objects<OT: JVDatabaseModel>(_ type: OT.Type, options: JVDatabaseRequestOptions?) -> [OT] {
        fatalError()
    }
    
    func object<OT: JVDatabaseModel>(_ type: OT.Type, internalId: NSManagedObjectID) -> OT? {
        fatalError()
    }
    
    func object<OT: JVDatabaseModel, VT: Hashable>(_ type: OT.Type, primaryId: VT) -> OT? {
        fatalError()
    }
    
    func object<OT: JVDatabaseModel, VT: Hashable>(_ type: OT.Type, customId: JVDatabaseModelCustomId<VT>) -> OT? {
        fatalError()
    }
    
    func subscribe<OT: JVDatabaseModel>(_ type: OT.Type, options: JVDatabaseRequestOptions?, callback: @escaping ([OT]) -> Void) -> JVDatabaseListener {
        fatalError()
    }
    
    func subscribe<OT: JVDatabaseModel>(object: OT, callback: @escaping (OT?) -> Void) -> JVDatabaseListener {
        fatalError()
    }
    
    func unsubscribe(_ token: JVDatabaseDriverSubscriberToken) {
        fatalError()
    }
    
    func simpleRemove<OT: JVDatabaseModel>(objects: [OT]) -> Bool {
        fatalError()
    }
    
    func customRemove<OT: JVDatabaseModel>(objects: [OT], recursive: Bool) {
        fatalError()
    }
    
    func removeAll() {
        fatalError()
    }
}
