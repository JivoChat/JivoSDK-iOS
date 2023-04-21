//
//  JVDatabaseContext.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 03/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import CoreData

public protocol JVIDatabaseContext: AnyObject {
    var context: JVDatabaseDriverMoc { get }
    var environment: JVIDatabaseEnvironment { get }

    var hasChanges: Bool { get }
    func performTransaction<Value>(actions: (JVIDatabaseContext) -> Value) -> Value
    
    func createObject<OT: JVDatabaseModel>(_ type: OT.Type) -> OT
    func add<OT: JVDatabaseModel>(_ objects: [OT])
    
    func observe<OT: JVDatabaseModel>(_ type: OT.Type) -> NSFetchedResultsController<OT>
    func objects<OT: JVDatabaseModel>(_ type: OT.Type, options: JVDatabaseRequestOptions?) -> [OT]
    func object<OT: JVDatabaseModel>(_ type: OT.Type, internalId: NSManagedObjectID) -> OT?
    func object<OT: JVDatabaseModel>(_ type: OT.Type, primaryId: Int) -> OT?
    func object<OT: JVDatabaseModel>(_ type: OT.Type, primaryId: String) -> OT?
    func object<OT: JVDatabaseModel, KT: Hashable>(_ type: OT.Type, customId: JVDatabaseModelCustomId<KT>) -> OT?
    func getObjects<OT: JVDatabaseModel>(_ type: OT.Type, options: JVDatabaseRequestOptions?) -> [OT]

    func simpleRemove<OT: JVDatabaseModel>(objects: [OT]) -> Bool
    func customRemove<OT: JVDatabaseModel>(objects: [OT], recursive: Bool)
    
    @discardableResult
    func removeAll() -> Bool
    
    func setValue(_ value: Int, for key: Int)
    func valueForKey(_ key: Int) -> Int?
    
    func find<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT?
    func insert<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT?
    func insert<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?, validOnly: Bool) -> OT?
    func insert<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]?) -> [OT]
    func insert<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]?, validOnly: Bool) -> [OT]
    func upsert<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT?
    func upsert<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?, validOnly: Bool) -> OT?
    func upsert<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]?) -> [OT]
    func upsert<OT: JVDatabaseModel>(_ model: OT?, with change: JVDatabaseModelChange?) -> OT?
    func update<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT?
    func replaceAll<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]) -> [OT]
    func models<MT: JVDatabaseModel>(for IDs: [Int]) -> [MT]
    
    func agent(for agentID: Int, provideDefault: Bool) -> JVAgent?
    func bot(for botID: Int, provideDefault: Bool) -> JVBot?
    func department(for departmentID: Int) -> JVDepartment?
    func client(for clientID: Int, needsDefault: Bool) -> JVClient?
    func clientID(for chatID: Int) -> Int?
    func chatWithID(_ ID: Int) -> JVChat?
    func messageWithCallID(_ callID: String?) -> JVMessage?
}

public typealias JVDatabaseDriverSubscriberToken = UUID

public struct JVDatabaseModelCustomId<VT: Hashable>: Hashable {
    let key: String
    let value: VT

    public init(key: String, value: VT) {
        self.key = key
        self.value = value
    }
}

public struct JVDatabaseRequestOptions {
    public let filter: NSPredicate?
    public let sortBy: [JVDatabaseResponseSort]
    public let notificationName: Notification.Name?
    
    public init(filter: NSPredicate? = nil, sortBy: [JVDatabaseResponseSort] = [], notificationName: Notification.Name? = nil) {
        self.filter = filter
        self.sortBy = sortBy
        self.notificationName = notificationName
    }
}

public struct JVDatabaseResponseSort {
    public let keyPath: String
    public let ascending: Bool
    
    public init(keyPath: String, ascending: Bool) {
        self.keyPath = keyPath
        self.ascending = ascending
    }
}
