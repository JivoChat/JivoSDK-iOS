//
//  IncrementalValueTool.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 11/10/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation


enum IncrementalStorageKind {
    case memory
    case preferences(accessor: PreferencesAccessor)
    case custom(IIncrementalStorage)
}

enum IncrementalRange {
    case unlimited
    case limited(_ by: Int, loop: Bool)
}

protocol IIncrementalTool: AnyObject {
    var reachedLimit: Bool { get }
    func next() -> Int
    func reset()
}

final class IncrementalTool: IIncrementalTool {
    private let storage: IIncrementalStorage
    private let range: IIncrementalRange

    init(storage storageKind: IncrementalStorageKind, range rangeKind: IncrementalRange) {
        switch storageKind {
        case .memory: storage = IncrementalMemoryStorage()
        case .preferences(let accessor): storage = IncrementalPreferencesStorage(accessor: accessor)
        case .custom(let custom): storage = custom
        }
        
        switch rangeKind {
        case .unlimited: range = IncrementalUnlimitedRange()
        case .limited(let limit, let loop): range = IncrementalLimitedRange(limit: limit, loop: loop)
        }
    }
    
    var reachedLimit: Bool {
        return range.reachedLimit(value: storage.value)
    }
    
    func next() -> Int {
        let value = range.adjust(value: storage.value + 1)
        storage.value = value
        return value
    }
    
    func reset() {
        storage.erase()
    }
}
