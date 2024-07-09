//
//  ArchiveHitEntity+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

enum JVArchiveHitSort {
    case byTime
    case byScore
}

extension ArchiveHitEntity {
    var ID: String {
        return m_id.jv_orEmpty
    }
    
    var item: ArchiveHitItemEntity? {
        return chatItem ?? callItem
    }
    
    var chatItem: ArchiveHitChatItemEntity? {
        return m_item as? ArchiveHitChatItemEntity
    }
    
    var callItem: ArchiveHitCallItemEntity? {
        return m_item as? ArchiveHitCallItemEntity
    }
    
    var chat: ChatEntity? {
        return item?.chat
    }
    
    var duration: TimeInterval {
        return item?.duration ?? 0
    }
    
    var score: Float {
        return m_score
    }
    
    var sortingRank: String {
        return m_sorting_rank.jv_orEmpty
    }
}
