//
//  JVArchiveHit+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVArchiveHit {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_str = m_id
        }
        
        if let c = change as? JVArchiveHitGeneralChange {
            if let chatItem = c.chatItem {
                m_item = context.upsert(of: JVArchiveHitChatItem.self, with: chatItem)
                m_item?.b_hit = self
            }
            else if let callItem = c.callItem {
                m_item = context.upsert(of: JVArchiveHitCallItem.self, with: callItem)
                m_item?.b_hit = self
            }
            
            m_id = c.ID
            m_score = c.score
            m_latest_activity_time = m_item?.chat?.lastMessage?.date
        }
    }
}

final class JVArchiveHitGeneralChange: JVDatabaseModelChange {
    public let ID: String
    public let score: Float
    public let chatItem: JVArchiveHitChatItemGeneralChange?
    public let callItem: JVArchiveHitCallItemGeneralChange?
    
    override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_id", value: ID)
    }
    
    override var isValid: Bool {
        if let item = chatItem, let change = item.chatChange, change.attendees.isEmpty { return true }
        if let _ = callItem { return true }
        return false
    }
    
    init(ID: String,
         score: Float,
         chatItem: JVArchiveHitChatItemGeneralChange?,
         callItem: JVArchiveHitCallItemGeneralChange?) {
        self.ID = ID
        self.score = score
        self.chatItem = chatItem
        self.callItem = callItem
        super.init()
    }
    
    required init(json: JsonElement) {
        ID = json["id"].stringValue
        score = json["score"].floatValue
        
        switch json["type"].stringValue {
        case "chat":
            chatItem = json["item"].parse()
            callItem = nil
            
        case "call":
            chatItem = nil
            callItem = json["item"].parse()
            
        default:
            chatItem = nil
            callItem = nil
        }
        
        super.init(json: json)
    }
    
    func copyUnrelative() -> JVArchiveHitGeneralChange {
        return JVArchiveHitGeneralChange(
            ID: ID,
            score: score,
            chatItem: chatItem?.copyUnrelative(),
            callItem: callItem?.copyUnrelative()
        )
    }
}
