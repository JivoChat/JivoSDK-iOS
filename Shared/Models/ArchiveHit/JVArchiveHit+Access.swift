//
//  JVArchiveHit+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

public enum JVArchiveHitSort {
    case byTime
    case byScore
}

extension JVArchiveHit {
    public var ID: String {
        return m_id.jv_orEmpty
    }
    
    public var item: JVArchiveHitItem? {
        return chatItem ?? callItem
    }
    
    public var chatItem: JVArchiveHitChatItem? {
        return m_item as? JVArchiveHitChatItem
    }
    
    public var callItem: JVArchiveHitCallItem? {
        return m_item as? JVArchiveHitCallItem
    }
    
    public var chat: JVChat? {
        return item?.chat
    }
    
    public var duration: TimeInterval {
        return item?.duration ?? 0
    }
    
    public var latestActivityTime: Date? {
        return m_latest_activity_time
    }
}
