//
//  PersistentRepository.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 26.11.2021.
//  Copyright © 2021 jivosite.mobile. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

//#warning("TODO: Anton Karpushko, 26.11.2021 – Make PersistentRepository thread-safe.")

class PersistentRepository<Index: Hashable, Item, Change: JVDatabaseModelChange, Model: JVDatabaseModel, MainKey: Hashable>: Repository<Index, Item> {
    private var semaphore = CountingSemaphore(value: 1)
    
    private var internalRepository: MemoryRepository<Index, Item>
    private let databaseDriver: JVIDatabaseDriver
    private let changeFromItem: (Item) -> Change
    private let itemFromModel: (Model) -> Item
    private let mainKeyFromIndex: (Index) -> JVDatabaseModelCustomId<MainKey>
    
    init(
        memoryRepository: MemoryRepository<Index, Item>,
        databaseDriver: JVIDatabaseDriver,
        changeFromItem: @escaping (Item) -> Change,
        itemFromModel: @escaping (Model) -> Item,
        mainKeyFromIndex: @escaping (Index) -> JVDatabaseModelCustomId<MainKey>,
        updateHandler: @escaping ([Item]) -> Void
    ) {
        self.internalRepository = memoryRepository
        self.databaseDriver = databaseDriver
        self.changeFromItem = changeFromItem
        self.itemFromModel = itemFromModel
        self.mainKeyFromIndex = mainKeyFromIndex
        
        super.init(
            itemIndex: memoryRepository.itemIndex,
            wasItemUpdated: memoryRepository.wasItemUpdated,
            updateHandler: memoryRepository.updateHandler
        )
        
        startup()
    }
    
    private func startup() {
        let models = self.databaseDriver.objects(Model.self, options: nil)
        let items = models.map(self.itemFromModel)
        semaphore.wait()
        internalRepository.removeAll { isRepositoryEmpty in
            if !isRepositoryEmpty {
                journal {"PersistentRepository cleaning error: something went wrong"}
            }
        }
        internalRepository.upsert(items) { upsertedItems in
            self.semaphore.signal()
            self.updateHandler(upsertedItems)
        }
    }
    
    private func lock<T>(_ protectedMemoryAccessBlock: () -> T) -> T {
        semaphore.wait()
        defer { semaphore.signal() }
        return protectedMemoryAccessBlock()
    }
    
    override func allItems(completion: @escaping ([Item]) -> Void) {
        semaphore.wait()
        internalRepository.allItems { items in
            self.semaphore.signal()
            completion(items)
        }
    }
    
    override func itemBy(index: Index, completion: @escaping (Item?) -> Void) {
        semaphore.wait()
        internalRepository.itemBy(index: index) { item in
            self.semaphore.signal()
            completion(item)
        }
    }
    
    override func upsert(_ items: [Item], completion: @escaping ([Item]) -> Void) {
        let changes = items.map(changeFromItem)
        self.databaseDriver.readwrite { context in
            let models = context.upsert(of: Model.self, with: changes)
            let itemsToUpsert = models.map(self.itemFromModel)
            
            semaphore.wait()
            self.internalRepository.upsert(itemsToUpsert) { upsertedItems in
                self.semaphore.signal()
                completion(upsertedItems)
            }
        }
    }
    
    override func upsert(_ items: Item..., completion: @escaping ([Item]) -> Void) {
        let itemsArray = Array<Item>(items)
        upsert(itemsArray, completion: completion)
    }
    
    override func removeItem(withIndex index: Index, completion: @escaping (Bool) -> Void) {
        lock {
            internalRepository.removeItem(withIndex: index) { _ in
            }
        }
        
        self.databaseDriver.readwrite { context in
            let mainKey = self.mainKeyFromIndex(index)
            let models = [context.object(Model.self, customId: mainKey)].compactMap { $0 }
            let result = context.simpleRemove(objects: models)
                
            completion(result)
        }
    }
    
    override func removeAll(completion: @escaping (Bool) -> Void) {
        self.databaseDriver.readwrite { context in
            if context.removeAll() {
                self.semaphore.wait()
                self.internalRepository.removeAll { isRepositoryEmpty in
                    self.semaphore.signal()
                    completion(isRepositoryEmpty)
                }
            } else {
                completion(false)
            }
        }
    }
}
