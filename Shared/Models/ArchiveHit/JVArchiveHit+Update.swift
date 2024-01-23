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
            m_id = c.ID
            m_sorting_rank = c.sortingRank
            m_score = c.score
            
            if let chatItem = c.chatItem {
                m_item = context.upsert(of: JVArchiveHitChatItem.self, with: chatItem)
                m_item?.b_hit = self
            }
            else if let callItem = c.callItem {
                m_item = context.upsert(of: JVArchiveHitCallItem.self, with: callItem)
                m_item?.b_hit = self
            }
        }
    }
}

final class JVArchiveHitGeneralChange: JVDatabaseModelChange {
    static var f_creationOrderCounter = Int.max
    
    let ID: String
    let creationOrder: Int
    let score: Float
    let sortingRank: String
    let chatItem: JVArchiveHitChatItemGeneralChange?
    let callItem: JVArchiveHitCallItemGeneralChange?
    
    override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_id", value: ID)
    }
    
    init(ID: String,
         creationOrder: Int,
         score: Float,
         sortingRank: String,
         chatItem: JVArchiveHitChatItemGeneralChange?,
         callItem: JVArchiveHitCallItemGeneralChange?) {
        self.ID = ID
        self.creationOrder = creationOrder
        self.score = score
        self.sortingRank = sortingRank
        self.chatItem = chatItem
        self.callItem = callItem
        super.init()
    }
    
    required init(json: JsonElement) {
        ID = json["id"].stringValue
        creationOrder = Self.f_creationOrderCounter.jv_decrement()
        score = json["score"].floatValue
        sortingRank = .jv_empty
        
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
            creationOrder: creationOrder,
            score: score,
            sortingRank: sortingRank,
            chatItem: chatItem,
            callItem: callItem
        )
    }
    
    func copy(sortingRank: String) -> JVArchiveHitGeneralChange {
        return JVArchiveHitGeneralChange(
            ID: ID,
            creationOrder: creationOrder,
            score: score,
            sortingRank: sortingRank,
            chatItem: chatItem,
            callItem: callItem
        )
    }
}
