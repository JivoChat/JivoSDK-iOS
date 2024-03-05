//
//  DatabaseContext_impl.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 09.04.2023.
//

import Foundation
import CoreData

fileprivate var exceptionHandler: (Error) -> Void = { _ in }
//func JVDatabaseContextSetExceptionHandler(_ handler: @escaping (Error) -> Void) { exceptionHandler = handler }

final class JVDatabaseContext: JVIDatabaseContext {
    private let storeCoordinator: NSPersistentStoreCoordinator
    private let namespace: String
    public let context: JVDatabaseDriverMoc
    public let environment: JVIDatabaseEnvironment
    
    private var listenerToken: NSObjectProtocol?

    private var isInWriteTransaction = false
    private var hasAddedObjects = false
    
    private var values = [Int: Int]()
    
    init(dispatcher: JVIDispatcher, storeCoordinator: NSPersistentStoreCoordinator, namespace: String, context: JVDatabaseDriverMoc, environment: JVIDatabaseEnvironment) {
        self.storeCoordinator = storeCoordinator
        self.namespace = namespace
        self.context = context
        self.environment = environment
        
        listenerToken = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: nil,
            using: { [weak self] notification in
                dispatcher.addOperation { [weak self] in
                    self?.handleUpdates(notification: notification)
                }
            })
    }
    
    var hasChanges: Bool {
        return hasAddedObjects
    }
    
    func createObject<OT: JVDatabaseModel>(_ type: OT.Type) -> OT {
        hasAddedObjects = true
        
        let entityName = String(describing: type)
        if let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? OT {
            return object
        }
        else {
            fatalError()
        }
    }
    
    func add<OT: JVDatabaseModel>(_ objects: [OT]) {
        hasAddedObjects = true
        
        for object in objects {
            if object.managedObjectContext == nil {
                context.insert(object)
            }
        }
    }
    
    func observe<OT: JVDatabaseModel>(_ type: OT.Type) -> NSFetchedResultsController<OT> {
        let entityName = String(describing: type)
        
        let fetchRequest = NSFetchRequest<OT>(entityName: entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "m_uid", ascending: true)]
        
        return NSFetchedResultsController<OT>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
    
    func objects<OT: JVDatabaseModel>(_ type: OT.Type, options: JVDatabaseRequestOptions?) -> [OT] {
        let objects = getObjects(type, options: options)
        return objects
    }
    
    func object<OT: JVDatabaseModel>(_ type: OT.Type, internalId: NSManagedObjectID) -> OT? {
        do {
            guard let value = try context.existingObject(with: internalId) as? OT
            else {
                return nil
            }
            
//            context.refresh(value, mergeChanges: false)
            return value
        }
        catch {
            handleException(error: error)
            return nil
        }
    }
    
    func object<OT: JVDatabaseModel>(_ type: OT.Type, primaryId: Int) -> OT? {
        let request = NSFetchRequest<OT>(entityName: String(describing: type))
        request.predicate = NSPredicate(format: "m_pk_num == %lld", primaryId)
        request.fetchLimit = 2
        
        do {
            let found = try context.fetch(request)
            
            #if JIVOSDK_DEBUG
            assert(found.count <= 1)
            #endif
            
            return found.first
        }
        catch {
            handleException(error: error)
            return nil
        }
    }
    
    func object<OT: JVDatabaseModel>(_ type: OT.Type, primaryId: String) -> OT? {
        let request = NSFetchRequest<OT>(entityName: String(describing: type))
        request.predicate = NSPredicate(format: "m_pk_str == %@", primaryId)
        request.fetchLimit = 2
        
        do {
            let found: [OT] = try context.fetch(request)
            
            #if JIVOSDK_DEBUG
            assert(found.count <= 1)
            #endif

            return found.first
        }
        catch {
            handleException(error: error)
            return nil
        }
    }
    
    func object<OT: JVDatabaseModel, KT: Hashable>(_ type: OT.Type, customId: JVDatabaseModelCustomId<KT>) -> OT? {
        let entityName = String(describing: type)
        
        let request = NSFetchRequest<OT>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K == %@", argumentArray: [customId.key, customId.value])
        request.fetchLimit = 2
        
        do {
            let found = try context.fetch(request)
            
            #if JIVOSDK_DEBUG
            assert(found.count <= 1)
            #endif
            
            return found.first
        }
        catch {
            handleException(error: error)
            return nil
        }
    }
    
    func simpleRemove<OT: JVDatabaseModel>(objects: [OT]) -> Bool {
        for object in objects {
            context.delete(object)
        }
        
        return true
    }
    
    func customRemove<OT: JVDatabaseModel>(objects: [OT], recursive: Bool) {
        for object in objects {
            context.delete(object)
        }
    }
    
    @discardableResult
    func removeAll() -> Bool {
        guard let store = storeCoordinator.persistentStores.first,
              let storeUrl = store.url
        else {
            return false
        }
        
        do {
            try storeCoordinator.remove(store)
            FileManager.default.jv_removeItem(at: storeUrl, strategy: .satellites)
            try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl)
            return true
        }
        catch {
            return false
        }
    }
    
    func setValue(_ value: Int, for key: Int) {
        values[key] = value
    }
    
    func valueForKey(_ key: Int) -> Int? {
        return values[key]
    }
    
    func performTransaction<Value>(actions: (JVIDatabaseContext) -> Value) -> Value {
        if isInWriteTransaction {
            return actions(self)
        }
        else {
            isInWriteTransaction = true
            defer {
                isInWriteTransaction = false
            }
            
            hasAddedObjects = false
            defer {
                hasAddedObjects = false
            }
            
            var value: Value
            do {
                value = actions(self)
                if context.hasChanges {
                    try context.save()
                }
            }
            catch let exc {
                exceptionHandler(exc)
                assertionFailure(exc.localizedDescription)
            }

            return value
        }
    }
    
//    internal func beginChanges() {
//        hasAddedObjects = false
//        realm.beginWrite()
//    }
//
//    internal func commitChanges() {
//        try! realm.commitWrite()
//        realm.refresh()
//        hasAddedObjects = false
//    }
    
    func getObjects<OT: JVDatabaseModel>(_ type: OT.Type, options: JVDatabaseRequestOptions?) -> [OT] {
        let entityName = String(describing: type)
        let request = NSFetchRequest<OT>(entityName: entityName)
        
        if let options = options {
            request.predicate = options.filter
            request.fetchLimit = options.limit
            request.propertiesToFetch = options.properties
            
            request.sortDescriptors = options.sortBy.map {
                NSSortDescriptor(key: $0.keyPath, ascending: $0.ascending)
            }
        }
        
        do {
            let found = try context.fetch(request)
            return found
        }
        catch {
            handleException(error: error)
            return Array()
        }
    }
    
    func find<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT? {
        if let change = change, change.isValid {
            if let integerKey = change.integerKey {
                let customId = JVDatabaseModelCustomId(key: integerKey.key, value: integerKey.value)
                return object(OT.self, customId: customId)
            }
            else if let stringKey = change.stringKey {
                let customId = JVDatabaseModelCustomId(key: stringKey.key, value: stringKey.value)
                return object(OT.self, customId: customId)
            }
            else if change.primaryValue != 0 {
                return object(OT.self, primaryId: change.primaryValue)
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }

    func insert<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT? {
        return insert(of: type, with: change, validOnly: false)
    }
    
    func insert<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?, validOnly: Bool) -> OT? {
        guard let change = change else {
            return nil
        }

        guard change.isValid || !validOnly else {
            return nil
        }

        let entityName = String(describing: type)
        if let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? OT {
            object.apply(context: self, change: change)
            add([object])
            return object
        }
        else {
            fatalError()
        }
    }
    
    func insert<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]?) -> [OT] {
        return insert(of: type, with: changes, validOnly: false)
    }
    
    func insert<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]?, validOnly: Bool) -> [OT] {
        guard let changes = changes else {
            return []
        }

        return changes.compactMap {
            insert(of: type, with: $0, validOnly: validOnly)
        }
    }
    
    func upsert<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT? {
        return upsert(of: type, with: change, validOnly: false)
    }
    
    func upsert<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?, validOnly: Bool) -> OT? {
        let (obj, _) = upsertCallback(of: type, with: change, validOnly: validOnly)
        return obj
    }
    
    func upsertCallback<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?, validOnly: Bool = false) -> (OT?, Bool) {
        var newlyAdded = false
        
        if let change = change, change.isValid {
            let obj: OT
            if let integerKey = change.integerKey {
                let customId = JVDatabaseModelCustomId(key: integerKey.key, value: integerKey.value)
                if let o = object(OT.self, customId: customId) {
                    obj = o
                    newlyAdded = false
                }
                else {
                    let entityName = String(describing: type)
                    if let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? OT {
                        obj = object
                        newlyAdded = true
                    }
                    else {
                        return (nil, false)
                    }
                }
            }
            else if let stringKey = change.stringKey {
                let customId = JVDatabaseModelCustomId(key: stringKey.key, value: stringKey.value)
                if let o = object(OT.self, customId: customId) {
                    obj = o
                    newlyAdded = false
                }
                else {
                    let entityName = String(describing: type)
                    if let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? OT {
                        obj = object
                        newlyAdded = true
                    }
                    else {
                        return (nil, false)
                    }
                }
            }
            else if change.primaryValue != 0 {
                if let o = object(OT.self, primaryId: change.primaryValue) {
                    obj = o
                    newlyAdded = false
                }
                else {
                    let entityName = String(describing: type)
                    if let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? OT {
                        obj = object
                        newlyAdded = true
                    }
                    else {
                        return (nil, false)
                    }
                }
            }
            else {
                let entityName = String(describing: type)
                if let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? OT {
                    obj = object
                    newlyAdded = true
                }
                else {
                    return (nil, false)
                }
            }
            
            obj.apply(context: self, change: change)
            obj.hasBeenChanged = obj.hasChanges
            
            if obj.managedObjectContext == nil {
                add([obj])
            }
            else if newlyAdded {
                hasAddedObjects = true
            }
            
            return (obj, newlyAdded)
        }
        else {
            return (nil, false)
        }
    }
    
    func upsert<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]?) -> [OT] {
        if let changes = changes {
            return changes.compactMap { upsert(of: type, with: $0) }
        }
        else {
            return []
        }
    }
    
    func upsert<OT: JVDatabaseModel>(_ model: OT?, with change: JVDatabaseModelChange?) -> OT? {
        guard let change = change else {
            return model
        }
        
        if let model = model {
            model.apply(context: self, change: change)
            return model
        }
        else {
            return insert(of: OT.self, with: change)
        }
    }
    
    func update<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT? {
        guard let change = change else {
            return nil
        }
        
        let obj: OT?
        if let integerKey = change.integerKey {
            let customId = JVDatabaseModelCustomId(key: integerKey.key, value: integerKey.value)
            if let foundObject = object(OT.self, customId: customId) {
                obj = foundObject
            }
            else if let stringKey = change.stringKey {
                let customId = JVDatabaseModelCustomId(key: stringKey.key, value: stringKey.value)
                obj = object(OT.self, customId: customId)
            }
            else {
                obj = nil
            }
        }
        else if let stringKey = change.stringKey {
            let customId = JVDatabaseModelCustomId(key: stringKey.key, value: stringKey.value)
            if let foundObject = object(OT.self, customId: customId) {
                obj = foundObject
            }
            else if let integerKey = change.integerKey {
                let customId = JVDatabaseModelCustomId(key: integerKey.key, value: integerKey.value)
                obj = object(OT.self, customId: customId)
            }
            else {
                obj = nil
            }
        }
        else if change.primaryValue != 0 {
            obj = object(OT.self, primaryId: change.primaryValue)
        }
        else {
            obj = nil
        }
        
        if let obj = obj, obj.jv_isValid {
            obj.apply(context: self, change: change)
        }
        
        return obj
    }
    
    func replaceAll<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]) -> [OT] {
        objects(type, options: nil).forEach(context.delete)
        let values = upsert(of: type, with: changes)
        return values
    }
    
    func models<MT: JVDatabaseModel>(for IDs: [Int]) -> [MT] {
        return IDs.compactMap { self.object(MT.self, primaryId: $0) }
    }
    
    func agent(for agentID: Int, provideDefault: Bool) -> JVAgent? {
        if let value = object(JVAgent.self, primaryId: agentID) {
            return value
        }
        else if provideDefault {
            return upsert(of: JVAgent.self, with: JVAgentGeneralChange(placeholderID: agentID))
        }
        else {
            return nil
        }
    }
    
    func bot(for botID: Int, provideDefault: Bool) -> JVBot? {
        if let value = object(JVBot.self, primaryId: botID) {
            return value
        }
        else if provideDefault {
            return upsert(of: JVBot.self, with: JVBotGeneralChange(placeholderID: botID))
        }
        else {
            return nil
        }
    }
    
    func department(for departmentID: Int) -> JVDepartment? {
        if let value = object(JVDepartment.self, primaryId: departmentID) {
            return value
        }
        else {
            return nil
        }
    }
    
    func client(for clientID: Int, needsDefault: Bool) -> JVClient? {
        if let value = object(JVClient.self, primaryId: clientID) {
            return value
        }
        else if needsDefault {
            return upsert(of: JVClient.self, with: JVClientGeneralChange(clientID: clientID))
        }
        else {
            return nil
        }
    }
    
    func clientID(for chatID: Int) -> Int? {
        if let value = valueForKey(chatID) {
            return value
        }
        else {
            return chatWithID(chatID)?.client?.ID
        }
    }
    
    func chatWithID(_ ID: Int) -> JVChat? {
        return object(JVChat.self, primaryId: ID)
    }
    
    func message(for messageId: Int, provideDefault: Bool) -> JVMessage? {
        if let value = object(JVMessage.self, primaryId: messageId) {
            return value
        }
        else if provideDefault {
            return upsert(of: JVMessage.self, with: JVMessageEmptyChange(ID: messageId))
        }
        else {
            return nil
        }
    }
    
    func messageWithCallID(_ callID: String?) -> JVMessage? {
        guard let callID = callID else { return nil }

        let filter = NSPredicate(format: "m_body.m_call_id == %@", callID)
        let options = JVDatabaseRequestOptions(filter: filter)
        return objects(JVMessage.self, options: options).last
    }
    
    func topic(for topicId: Int, needsDefault: Bool) -> JVTopic? {
        if let value = object(JVTopic.self, primaryId: topicId) {
            return value
        }
        else if needsDefault {
            return upsert(of: JVTopic.self, with: JVTopicEmptyChange(id: topicId))
        }
        else {
            return nil
        }
    }
    
    private func handleException(error: Error) {
        if (error as NSError).code == 522 {
            removeAll()
//            fatalError("Erase the database due to CoreData 522 error")
        }
    }
    
    private func handleUpdates(notification: Notification) {
        guard let anotherContext = notification.object as? JVDatabaseDriverMoc,
              anotherContext.namespace == context.namespace
        else {
            return
        }
        
        if anotherContext !== context {
            context.mergeChanges(fromContextDidSave: notification)
        }
    }
}
