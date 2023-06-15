//
//  Repository.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 26.11.2021.
//  Copyright © 2021 jivosite.mobile. All rights reserved.
//

import Foundation

class Repository<ExternalIndex: Hashable, ExternalItem> {
    let itemIndex: (ExternalItem) -> ExternalIndex
    let wasItemUpdated: (ExternalItem, ExternalItem) -> Bool
    let updateHandler: ([ExternalItem]) -> Void
    
    init(
        itemIndex: @escaping (ExternalItem) -> ExternalIndex,
        wasItemUpdated: @escaping (ExternalItem, ExternalItem) -> Bool,
        updateHandler: @escaping ([ExternalItem]) -> Void
    ) {
        self.itemIndex = itemIndex
        self.wasItemUpdated = wasItemUpdated
        self.updateHandler = updateHandler
    }
    
    func allItems(completion: @escaping ([ExternalItem]) -> Void) {
        preconditionFailure()
    }
    
    func itemBy(index: ExternalIndex, completion: @escaping (ExternalItem?) -> Void) {
        preconditionFailure()
    }
    
    func upsert(_ items: [ExternalItem], completion: @escaping ([ExternalItem]) -> Void) {
        preconditionFailure()
    }
    
    func upsert(_ items: ExternalItem..., completion: @escaping ([ExternalItem]) -> Void) {
        preconditionFailure()
    }
    
    func removeItem(withIndex index: ExternalIndex, completion: @escaping (Bool) -> Void) {
        preconditionFailure()
    }
    
    func removeAll(completion: @escaping (Bool) -> Void) {
        preconditionFailure()
    }
}
