//
//  DatabaseDriver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 03/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import CoreData

enum JVDatabaseWriting {
    case anyThread
    case backgroundThread
}

fileprivate struct DatabaseFetchingToken {
    let fetchController: NSFetchedResultsController<NSFetchRequestResult>
    let fetchDelegate: NSFetchedResultsControllerDelegate
}

class JVDatabaseDriver: JVIDatabaseDriver {
    private let thread: JVIDispatchThread
    private let namespace: String
    private let writing: JVDatabaseWriting
    private let fileURL: URL?
    private let environment: JVIDatabaseEnvironment

    private var readonlyContext: JVIDatabaseContext?
    private var readwriteContext: JVIDatabaseContext?
    private var tokens = [JVDatabaseDriverSubscriberToken: DatabaseFetchingToken]()
    private var runners = [JVDatabaseDriverSubscriberToken: Any]()

    private var recentThread: Thread?
    private var recentRunLoop: RunLoop?
    
    let localizer: JVLocalizer
    
    private let container: NSPersistentContainer

    init(thread: JVIDispatchThread, fileManager: FileManager, namespace: String, writing: JVDatabaseWriting, fileURL: URL?, environment: JVIDatabaseEnvironment, localizer: JVLocalizer) {
        self.thread = thread
        self.namespace = namespace
        self.writing = writing
        self.fileURL = fileURL
        self.environment = environment
        self.localizer = localizer
        
        guard let momUrl = Bundle(for: DatabaseEntity.self).jv_findDatabaseScheme(basename: "JVDatabase") else {
            fatalError()
        }
        
        guard let momContent = NSManagedObjectModel(contentsOf: momUrl) else {
            fatalError()
        }
        
        container = NSPersistentContainer(
            name: namespace,
            managedObjectModel: momContent
        )
        
        setupPersistentContainer(
            fileManager: fileManager,
            fileUrl: fileURL,
            step: .initial)
    }
    
    private func setupPersistentContainer(fileManager: FileManager, fileUrl: URL?, step: _PersistentContainerSetupStep) {
        if let fileUrl {
            let storeDescription = NSPersistentStoreDescription()
            storeDescription.type = NSSQLiteStoreType
            storeDescription.url = fileUrl
            container.persistentStoreDescriptions = [storeDescription]
        }
        else {
            let storeDescription = NSPersistentStoreDescription()
            storeDescription.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        let containerName = container.name
        container.loadPersistentStores { [unowned self] info, error in
            if let error = error {
                fileManager.jv_removeItem(at: info.url, strategy: .satellites)
                
                switch step {
                case .initial:
                    print("Persistent Store failure for '\(containerName)' with error: \(error)")
                    setupPersistentContainer(
                        fileManager: fileManager,
                        fileUrl: fileUrl,
                        step: .recovery)
                case .recovery:
                    print("Failed to setup the Persistent Store, roll back to In-Memory")
                    setupPersistentContainer(
                        fileManager: fileManager,
                        fileUrl: nil,
                        step: .recovery)
                }
            }
            else if let url = info.url {
                print("Persistent Store is ready for '\(containerName)' with file: \(url)")
            }
        }
    }

    func refresh() -> JVIDatabaseDriver {
        return self
    }

    func reference<OT: DatabaseEntity>(to object: OT?) -> DatabaseEntityRef<OT> {
        return DatabaseEntityRef(coreDataDriver: self, value: object)
    }
    
    func resolve<OT: DatabaseEntity>(ref: DatabaseEntityRef<OT>) -> OT? {
        guard let objectId = ref.objectId
        else {
            return nil
        }
        
        let value = context.object(OT.self, internalId: objectId)
        return value
    }
    
    func read(_ block: (JVIDatabaseContext) -> Void) {
        context.performTransaction { ctx in
            block(ctx)
        }
    }
    
    func readwrite(_ block: (JVIDatabaseContext) -> Void) {
        switch writing {
        case .backgroundThread:
            #if JIVOSDK_DEBUG
            assert(!Thread.isMainThread, "Please use background thread for modifications")
            #endif
            break
        case .anyThread:
            break
        }
        
        context.performTransaction { ctx in
            block(ctx)
        }
    }
    
    func objects<OT: DatabaseEntity>(_ type: OT.Type, options: JVDatabaseRequestOptions?) -> [OT] {
        return context.objects(type, options: options)
    }
    
    func object<OT: DatabaseEntity>(_ type: OT.Type, internalId: NSManagedObjectID) -> OT? {
        return context.object(type, internalId: internalId)
    }
    
    func object<OT: DatabaseEntity, VT: Hashable>(_ type: OT.Type, primaryId: VT) -> OT? {
        if let key = primaryId as? String {
            return context.object(type, primaryId: key)
        }
        else if let key = primaryId as? Int {
            return context.object(type, primaryId: key)
        }
        else {
            return nil
        }
    }
    
    func object<OT: DatabaseEntity, VT: Hashable>(_ type: OT.Type, customId: JVDatabaseModelCustomId<VT>) -> OT? {
        return context.object(type, customId: customId)
    }
    
    final class SubscriptionManyDelegate<OT: DatabaseEntity>: NSObject, NSFetchedResultsControllerDelegate {
        private let debugging: String
        private let feedHandler: ([OT]) -> Void
        
        init(debugging: String, feedHandler: @escaping ([OT]) -> Void) {
            self.debugging = debugging
            self.feedHandler = feedHandler
            
            super.init()
            
//            print("[ASSIGN] Delegate init [\(debugging)]")
        }
        
        deinit {
//            print("[ASSIGN] Delegate deinit [\(debugging)]")
        }
        
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//            print("[ASSIGN] Delegate controllerDidChangeContent [\(debugging)]")
            
            guard let objects = controller.fetchedObjects as? [OT]
            else {
                return
            }
            
//            print("[ASSIGN] Delegate [\(debugging)] objects[\(objects)]")
            feedHandler(objects)
        }
    }
    
    func subscribe<OT: DatabaseEntity>(_ type: OT.Type, options: JVDatabaseRequestOptions?, callback: @escaping ([OT]) -> Void) -> JVDatabaseListener {
        let objects = context.getObjects(type, options: options)
        callback(objects)
        
        let fetchController = context.observe(OT.self)
        
        if let options = options {
            fetchController.fetchRequest.predicate = options.filter
            
            fetchController.fetchRequest.sortDescriptors = options.sortBy.map {
                NSSortDescriptor(key: $0.keyPath, ascending: $0.ascending)
            }
        }
        
        let fetchDelegate = SubscriptionManyDelegate(
            debugging: String(describing: fetchController.fetchRequest.predicate),
            feedHandler: callback
        )
        fetchController.delegate = fetchDelegate
        
        do {
            try fetchController.performFetch()
        }
        catch {
            
        }
        
        let internalToken = UUID()
        tokens[internalToken] = DatabaseFetchingToken(
            fetchController: fetchController as! NSFetchedResultsController<NSFetchRequestResult>,
            fetchDelegate: fetchDelegate
        )
        
        return JVDatabaseListener(token: internalToken, coreDataDriver: self)
    }
    
    final class SubscriptionSingleDelegate<OT: DatabaseEntity> {
        private let threadContext: NSManagedObjectContext
        private let object: OT
        private let feedHandler: (OT?) -> Void
        
        private var listenerToken: NSObjectProtocol?
        
        init(context: NSManagedObjectContext, object: OT, feedHandler: @escaping (OT?) -> Void) {
            self.threadContext = context
            self.object = object
            self.feedHandler = feedHandler
            
            feedHandler(object)
            
            listenerToken = NotificationCenter.default.addObserver(
                forName: .NSManagedObjectContextDidSave,
                object: nil,
                queue: .current,
                using: { [weak self] notification in
                    self?.handleUpdates(notification: notification)
                })
        }
        
        deinit {
            if let token = listenerToken {
                NotificationCenter.default.removeObserver(token)
            }
        }
        
        private func handleUpdates(notification: Notification) {
            guard (notification.object as? AnyObject) !== threadContext
            else {
                return
            }
            
            let deletedObjectsIds = notification.extractObjects(forKey: NSDeletedObjectsKey).map(\.objectID)
            if deletedObjectsIds.contains(object.objectID) {
                feedHandler(nil)
                return
            }
            
            let updatedObjectsIds = notification.extractObjects(forKey: NSUpdatedObjectsKey).map(\.objectID)
            if updatedObjectsIds.contains(object.objectID) {
                feedHandler(object)
                return
            }
        }
    }
    
    func subscribe<OT: DatabaseEntity>(object: OT, callback: @escaping (OT?) -> Void) -> JVDatabaseListener {
        let runner = SubscriptionSingleDelegate(
            context: context.context,
            object: object,
            feedHandler: callback
        )
        
        let internalToken = UUID()
        runners[internalToken] = runner
        
        return JVDatabaseListener(token: internalToken, coreDataDriver: self)
    }
    
    func unsubscribe(_ token: JVDatabaseDriverSubscriberToken) {
        if let item = tokens[token] {
            item.fetchController.delegate = nil
            tokens.removeValue(forKey: token)
        }
        else if let _ = runners[token] {
            runners.removeValue(forKey: token)
        }
    }
    
    func simpleRemove<OT: DatabaseEntity>(objects: [OT]) -> Bool {
        return context.performTransaction { ctx in
            ctx.simpleRemove(objects: objects)
        }
    }
    
    func customRemove<OT: DatabaseEntity>(objects: [OT], recursive: Bool) {
        context.performTransaction { ctx in
            ctx.customRemove(objects: objects, recursive: recursive)
        }
    }
    
    func removeAll() {
        _ = context.performTransaction { ctx in
            ctx.removeAll()
        }
    }
    
    private var context: JVIDatabaseContext {
        if Thread.isMainThread {
            if let object = readonlyContext {
                return object
            }
            else {
                let cdc = JVDatabaseDriverMoc(namespace: namespace, concurrencyType: .mainQueueConcurrencyType)
                cdc.name = "\(namespace).database.context.main"
                cdc.persistentStoreCoordinator = container.persistentStoreCoordinator
                cdc.automaticallyMergesChangesFromParent = true
                cdc.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
                
                let object = JVDatabaseContext(
                    dispatcher: OperationQueue.main,
                    storeCoordinator: container.persistentStoreCoordinator,
                    namespace: namespace,
                    context: cdc,
                    environment: environment
                )
                
                readonlyContext = object
                return object
            }
        }
        else {
            if recentThread == nil {
                recentThread = Thread.current
                recentRunLoop = RunLoop.current
            }
            
            if let object = readwriteContext {
                #if JIVOSDK_DEBUG
                assert(Thread.current === recentThread)
                assert(RunLoop.current === recentRunLoop)
                #endif

                return object
            }
            else {
                // SP: To avoid warnings about <.confinementConcurrencyType> is deprecated,
                // Use init(rawValue:) to create it in runtime
                let ctype = NSManagedObjectContextConcurrencyType(rawValue: 0) ?? .privateQueueConcurrencyType
                
                let cdc = JVDatabaseDriverMoc(namespace: namespace, concurrencyType: ctype)
                cdc.name = "\(namespace).database.context.engine"
                cdc.persistentStoreCoordinator = container.persistentStoreCoordinator
                cdc.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
                
                let object = JVDatabaseContext(
                    dispatcher: thread,
                    storeCoordinator: container.persistentStoreCoordinator,
                    namespace: namespace,
                    context: cdc,
                    environment: environment
                )
                
                readwriteContext = object
                return object
            }
        }
    }
}

fileprivate enum _PersistentContainerSetupStep {
    case initial
    case recovery
}

fileprivate extension Notification {
    func extractObjects(forKey key: String) -> Set<NSManagedObject> {
        if let objects = userInfo?[key] as? Set<NSManagedObject> {
            return objects
        }
        else {
            return Set()
        }
    }
}
