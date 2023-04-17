//
//  DatabaseDriverDecl.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 08.03.2023.
//

import Foundation
import CoreData

public protocol JVIDatabaseDriver: AnyObject {
    func refresh() -> JVIDatabaseDriver

    func reference<OT: JVDatabaseModel>(to object: OT?) -> JVDatabaseModelRef<OT>
    func resolve<OT: JVDatabaseModel>(ref: JVDatabaseModelRef<OT>) -> OT?
    
    func read(_ block: (JVIDatabaseContext) -> Void)
    func readwrite(_ block: (JVIDatabaseContext) -> Void)

    func objects<OT: JVDatabaseModel>(_ type: OT.Type, options: JVDatabaseRequestOptions?) -> [OT]
    func object<OT: JVDatabaseModel>(_ type: OT.Type, internalId: NSManagedObjectID) -> OT?
    func object<OT: JVDatabaseModel, VT: Hashable>(_ type: OT.Type, primaryId: VT) -> OT?
    func object<OT: JVDatabaseModel, VT: Hashable>(_ type: OT.Type, customId: JVDatabaseModelCustomId<VT>) -> OT?
    
    func subscribe<OT: JVDatabaseModel>(_ type: OT.Type, options: JVDatabaseRequestOptions?, callback: @escaping ([OT]) -> Void) -> JVDatabaseListener
    func subscribe<OT: JVDatabaseModel>(object: OT, callback: @escaping (OT?) -> Void) -> JVDatabaseListener
    func unsubscribe(_ token: JVDatabaseDriverSubscriberToken)
    
    func simpleRemove<OT: JVDatabaseModel>(objects: [OT]) -> Bool
    func customRemove<OT: JVDatabaseModel>(objects: [OT], recursive: Bool)
    func removeAll()
}
