//
//  JVDatabaseContext.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 03/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import CoreData

protocol JVIDatabaseContext: AnyObject {
    var context: JVDatabaseDriverMoc { get }
    var environment: JVIDatabaseEnvironment { get }

    var hasChanges: Bool { get }
    func performTransaction<Value>(actions: (JVIDatabaseContext) -> Value) -> Value
    
    func createObject<OT: DatabaseEntity>(_ type: OT.Type) -> OT
    func add<OT: DatabaseEntity>(_ objects: [OT])
    
    func observe<OT: DatabaseEntity>(_ type: OT.Type) -> NSFetchedResultsController<OT>
    func objects<OT: DatabaseEntity>(_ type: OT.Type, options: JVDatabaseRequestOptions?) -> [OT]
    func object<OT: DatabaseEntity>(_ type: OT.Type, internalId: NSManagedObjectID) -> OT?
    func object<OT: DatabaseEntity>(_ type: OT.Type, primaryId: Int) -> OT?
    func object<OT: DatabaseEntity>(_ type: OT.Type, primaryId: String) -> OT?
    func object<OT: DatabaseEntity, KT: Hashable>(_ type: OT.Type, customId: JVDatabaseModelCustomId<KT>) -> OT?
    func getObjects<OT: DatabaseEntity>(_ type: OT.Type, options: JVDatabaseRequestOptions?) -> [OT]

    func simpleRemove<OT: DatabaseEntity>(objects: [OT]) -> Bool
    func customRemove<OT: DatabaseEntity>(objects: [OT], recursive: Bool)
    
    @discardableResult
    func removeAll() -> Bool
    
    func setValue(_ value: Int, for key: Int)
    func valueForKey(_ key: Int) -> Int?
    
    func find<OT: DatabaseEntity>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT?
    func insert<OT: DatabaseEntity>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT?
    func insert<OT: DatabaseEntity>(of type: OT.Type, with change: JVDatabaseModelChange?, validOnly: Bool) -> OT?
    func insert<OT: DatabaseEntity>(of type: OT.Type, with changes: [JVDatabaseModelChange]?) -> [OT]
    func insert<OT: DatabaseEntity>(of type: OT.Type, with changes: [JVDatabaseModelChange]?, validOnly: Bool) -> [OT]
    func upsert<OT: DatabaseEntity>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT?
    func upsert<OT: DatabaseEntity>(of type: OT.Type, with change: JVDatabaseModelChange?, validOnly: Bool) -> OT?
    func upsert<OT: DatabaseEntity>(of type: OT.Type, with changes: [JVDatabaseModelChange]?) -> [OT]
    func upsert<OT: DatabaseEntity>(_ model: OT?, with change: JVDatabaseModelChange?) -> OT?
    func update<OT: DatabaseEntity>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT?
    func replaceAll<OT: DatabaseEntity>(of type: OT.Type, with changes: [JVDatabaseModelChange]) -> [OT]
    func models<MT: DatabaseEntity>(for IDs: [Int]) -> [MT]
    
    func agent(for agentID: Int, provideDefault: Bool) -> AgentEntity?
    func bot(for botID: Int, provideDefault: Bool) -> BotEntity?
    func department(for departmentID: Int) -> DepartmentEntity?
    func client(for clientID: Int, needsDefault: Bool) -> ClientEntity?
    func clientID(for chatID: Int) -> Int?
    func chatWithID(_ ID: Int) -> ChatEntity?
    func message(for messageId: Int, provideDefault: Bool) -> MessageEntity?
    func messageWithCallID(_ callID: String?) -> MessageEntity?
    func topic(for topicId: Int, needsDefault: Bool) -> TopicEntity?
}

typealias JVDatabaseDriverSubscriberToken = UUID

struct JVDatabaseModelCustomId<VT: Hashable>: Hashable {
    let key: String
    let value: VT

    init(key: String, value: VT) {
        self.key = key
        self.value = value
    }
}

struct JVDatabaseRequestOptions {
    let filter: NSPredicate?
    let limit: Int
    let properties: [String]
    let sortBy: [JVDatabaseResponseSort]
    let notificationName: Notification.Name?
    
    init(
        filter: NSPredicate? = nil,
        limit: Int = 0,
        properties: [String] = .jv_empty,
        sortBy: [JVDatabaseResponseSort] = .jv_empty,
        notificationName: Notification.Name? = nil
    ) {
        self.filter = filter
        self.limit = limit
        self.properties = properties
        self.sortBy = sortBy
        self.notificationName = notificationName
    }
}

struct JVDatabaseResponseSort {
    let keyPath: String
    let ascending: Bool
}
