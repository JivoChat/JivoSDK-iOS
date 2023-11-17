//
//  JVArchive+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension JVArchive {
    var latest: Double? {
        return (m_latest == 0 ? nil : m_latest)
    }
    
    var lastID: String? {
        return m_last_id?.jv_valuable
    }
    
    var total: Int {
        return Int(m_total)
    }
    
    var archiveTotal: Int {
        return Int(m_archite_total)
    }
    
    var hits: [JVArchiveHit] {
        if let allObjects = m_hits?.allObjects as? [JVArchiveHit] {
            return allObjects
        }
        else {
            assertionFailure()
            return Array()
        }
    }
    
    var isCleanedUp: Bool {
        return m_is_cleaned_up
    }
    
    func sortedHits(by sort: JVArchiveHitSort) -> [JVArchiveHit] {
        switch sort {
        case .byTime:
            return hits
                .sorted { fst, snd in
                    let fstRank = fst.sortingRank
                    let sndRank = snd.sortingRank
                    return (fstRank > sndRank)
                }
                .reversed()
            
        case .byScore:
            return hits
                .sorted { fst, snd in
                    let fstScore = fst.score
                    let sndScore = snd.score
                    return (fstScore < sndScore)
                }
                .reversed()
        }
    }
}
