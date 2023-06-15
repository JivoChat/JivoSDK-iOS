//
//  MemoryRepository.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 08.10.2021.
//

import Foundation

//#warning("TODO: Anton Karpushko, 26.11.2021 – Make MemoryRepository thread-safe.")

final class MemoryRepository<Index: Hashable, Item>: Repository<Index, Item> {
    typealias InternalCollectionType = [Index: Item]
    
    private let lock = NSLock()
    
    private var itemsDictionary: InternalCollectionType = [:]
    private var indexes: [Index] = [] // We need this property to save the order of items dictionary
    
    init(
        _ array: [Item] = [],
        indexItemsBy itemIndex: @escaping (Item) -> Index,
        wasItemUpdated: @escaping (Item, Item) -> Bool = { _, _ in return true },
        updateHandler: @escaping ([Item]) -> Void = { _ in }
    ) {
        self.itemsDictionary = Dictionary(uniqueKeysWithValues: array.map { (itemIndex($0), $0) })
        
        super.init(
            itemIndex: itemIndex,
            wasItemUpdated: wasItemUpdated,
            updateHandler: updateHandler
        )
    }
    
    // If you need to write some key-value pair to itemsDictionary, you must ALWAYS use the method below to keep itemsDictionary and itemsArray synchronized.
    private func upsert(item: Item?, withIndex index: Index) {
        lock.lock()
        
        itemsDictionary[index] = item
        
        if let _ = item {
            guard indexes.first(where: { $0 == index }) == nil else { return lock.unlock() }
            indexes.append(index)
        } else {
            indexes.removeAll { $0 == index }
        }
        
        lock.unlock()
    }
    
    override func allItems(completion: @escaping ([Item]) -> Void) {
        lock.lock()
        let unwrappedItems = indexes.map { itemsDictionary[$0] }
        lock.unlock()
        
        if unwrappedItems.contains(where: { $0 == nil }) {
            journal {"MemoryRepository object: some dictionary items that has stored keys in indexes array are nil"}
        }
        completion(unwrappedItems.compactMap { $0 })
    }
    
    override func itemBy(index: Index, completion: @escaping (Item?) -> Void) {
        lock.lock()
        completion(itemsDictionary[index])
        lock.unlock()
    }
    
    override func upsert(_ items: [Item], completion: @escaping ([Item]) -> Void) {
        let updatedItems = items.compactMap { (item: Item) -> Item? in
            let index = itemIndex(item)
            
            lock.lock()
            let itemToUpdate = itemsDictionary[index]
            lock.unlock()
            
            upsert(item: item, withIndex: index)
            
            if let itemToUpdate = itemToUpdate {
                return wasItemUpdated(itemToUpdate, item) ? item : nil
            } else {
                return item
            }
        }
        
        completion(updatedItems)
    }
    
    override func upsert(_ items: Item..., completion: @escaping ([Item]) -> Void) {
        let itemsArray = Array<Item>(items)
        return upsert(itemsArray, completion: completion)
    }
    
    override func removeItem(withIndex index: Index, completion: @escaping (Bool) -> Void) {
        upsert(item: nil, withIndex: index)
        completion(true)
    }
    
    override func removeAll(completion: @escaping (Bool) -> Void) {
        lock.lock()
        itemsDictionary.removeAll()
        indexes.removeAll()
        lock.unlock()
        
        completion(true)
    }
}

extension MemoryRepository: Collection {
    typealias InternalCollectionIndex = InternalCollectionType.Index
    typealias InternalCollectionElement = InternalCollectionType.Element
    
    var startIndex: InternalCollectionIndex {
        lock.lock()
        let startIndex = itemsDictionary.startIndex
        lock.unlock()
        
        return startIndex
    }
    
    var endIndex: InternalCollectionIndex {
        lock.lock()
        let endIndex = itemsDictionary.endIndex
        lock.unlock()
        
        return endIndex
    }
    
    subscript(_ index: InternalCollectionIndex) -> InternalCollectionElement {
        get {
            lock.lock()
            let item = itemsDictionary[index]
            lock.unlock()
            
            return item
        }
    }
    
    func index(after index: InternalCollectionIndex) -> InternalCollectionIndex {
        lock.lock()
        let index = itemsDictionary.index(after: index)
        lock.unlock()
        
        return index
    }
}

