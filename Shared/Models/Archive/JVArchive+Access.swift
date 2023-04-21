//
//  JVArchive+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension JVArchive {
    public var latest: Double? {
        return (m_latest == 0 ? nil : m_latest)
    }
    
    public var lastID: String? {
        return m_last_id?.jv_valuable
    }
    
    public var total: Int {
        return Int(m_total)
    }
    
    public var archiveTotal: Int {
        return Int(m_archite_total)
    }
    
    public var hits: [JVArchiveHit] {
        if let allObjects = m_hits?.allObjects as? [JVArchiveHit] {
            return allObjects
        }
        else {
            assertionFailure()
            return Array()
        }
    }
    
    public var isCleanedUp: Bool {
        return m_is_cleaned_up
    }
    
    public func sortedHits(by sort: JVArchiveHitSort) -> [JVArchiveHit] {
        switch sort {
        case .byTime:
            return hits
                .sorted { fst, snd in
                    let fstDate = fst.m_latest_activity_time ?? .distantPast
                    let sndDate = snd.m_latest_activity_time ?? .distantPast
                    return (fstDate < sndDate)
                }
                .reversed()
            
        case .byScore:
            return hits
                .sorted { fst, snd in
                    let fstScore = fst.m_score
                    let sndScore = snd.m_score
                    return (fstScore < sndScore)
                }
                .reversed()
        }
    }
}
