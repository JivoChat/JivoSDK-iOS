//
//  DatabaseDriverDecl.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 08.03.2023.
//

import Foundation
import CoreData

protocol JVIDatabaseDriver: AnyObject {
    func refresh() -> JVIDatabaseDriver

    func reference<OT: DatabaseEntity>(to object: OT?) -> DatabaseEntityRef<OT>
    func resolve<OT: DatabaseEntity>(ref: DatabaseEntityRef<OT>) -> OT?
    
    func read(_ block: (JVIDatabaseContext) -> Void)
    func readwrite(_ block: (JVIDatabaseContext) -> Void)

    func objects<OT: DatabaseEntity>(_ type: OT.Type, options: JVDatabaseRequestOptions?) -> [OT]
    func object<OT: DatabaseEntity>(_ type: OT.Type, internalId: NSManagedObjectID) -> OT?
    func object<OT: DatabaseEntity, VT: Hashable>(_ type: OT.Type, primaryId: VT) -> OT?
    func object<OT: DatabaseEntity, VT: Hashable>(_ type: OT.Type, customId: JVDatabaseModelCustomId<VT>) -> OT?
    
    func subscribe<OT: DatabaseEntity>(_ type: OT.Type, options: JVDatabaseRequestOptions?, callback: @escaping ([OT]) -> Void) -> JVDatabaseListener
    func subscribe<OT: DatabaseEntity>(object: OT, callback: @escaping (OT?) -> Void) -> JVDatabaseListener
    func unsubscribe(_ token: JVDatabaseDriverSubscriberToken)
    
    func simpleRemove<OT: DatabaseEntity>(objects: [OT]) -> Bool
    func customRemove<OT: DatabaseEntity>(objects: [OT], recursive: Bool)
    func removeAll()
}
