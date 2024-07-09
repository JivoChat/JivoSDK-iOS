//
//  ArchiveEntity+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

fileprivate let JVArchivePrimaryId = 1

extension ArchiveEntity {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = JVArchivePrimaryId.jv_toInt64(.standard)
        }
        
        if let c = change as? JVArchiveSliceChange {
            m_total = c.total.jv_toInt64(.standard)
            m_archite_total = c.archiveTotal.jv_toInt64(.standard)
            m_latest = c.latest ?? m_latest
            m_last_id = c.lastID ?? m_last_id
            
            let models: [JVArchiveHitGeneralChange] = c.hits.map { model in
                let prefix = String(format: "%032d", c.latest.jv_orZero)
                let suffix = String(format: "%032d", model.creationOrder)
                return model.copy(sortingRank: "\(prefix):\(suffix)")
            }
            
            if c.fresh {
                e_hits.setSet(Set(context.upsert(of: ArchiveHitEntity.self, with: models)))
            }
            else {
                e_hits.addObjects(from: models.compactMap { model in
                    if let object = context.object(ArchiveHitEntity.self, primaryId: model.ID) {
                        return object
                    }
                    else {
                        return context.upsert(of: ArchiveHitEntity.self, with: model)
                    }
                })
            }
            
            m_is_cleaned_up = false
        }
        else if let _ = change as? JVArchiveCleanupChange {
            m_total = 0
            m_latest = 0
            m_last_id = nil
            e_hits.removeAllObjects()
            m_is_cleaned_up = true
        }
    }
    
    private var e_hits: NSMutableSet {
        return mutableSetValue(forKeyPath: #keyPath(ArchiveEntity.m_hits))
    }
}

final class JVArchiveSliceChange: JVDatabaseModelChange {
    public let fresh: Bool
    public let status: Bool
    public let total: Int
    public let archiveTotal: Int
    public let latest: Double?
    public let lastID: String?
    public let hits: [JVArchiveHitGeneralChange]
    
    init(fresh: Bool,
         status: Bool,
         total: Int,
         archiveTotal: Int,
         latest: Double?,
         lastID: String?,
         hits: [JVArchiveHitGeneralChange]) {
        self.fresh = fresh
        self.status = status
        self.total = total
        self.archiveTotal = archiveTotal
        self.latest = latest
        self.lastID = lastID
        self.hits = hits
        
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
    
    override var primaryValue: Int {
        return JVArchivePrimaryId
    }
    
    func copy(fresh: Bool) -> JVArchiveSliceChange {
        return JVArchiveSliceChange(
            fresh: fresh,
            status: status,
            total: total,
            archiveTotal: archiveTotal,
            latest: latest,
            lastID: lastID,
            hits: hits.map { $0.copyUnrelative() }
        )
    }
}

final class JVArchiveCleanupChange: JVDatabaseModelChange {
    override var primaryValue: Int {
        return JVArchivePrimaryId
    }
}
