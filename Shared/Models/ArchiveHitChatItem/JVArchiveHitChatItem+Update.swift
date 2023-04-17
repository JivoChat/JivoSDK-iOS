//
//  JVArchiveHitChatItem+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVArchiveHitChatItem {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_str = m_id
        }
        
        if let c = change as? JVArchiveHitChatItemGeneralChange {
            m_id = c.ID
            m_type = c.type
            m_response_timeout = c.responseTimeout.jv_toInt32
            m_duration = c.duration.jv_toInt32
            m_events_number = Int16(c.eventsNumber)
            e_agents.setSet(Set(c.agentIDs.compactMap { context.object(JVAgent.self, primaryId: $0) }))
            m_latest_chat_id = Int64(c.latestChatID)
            m_chat = context.upsert(of: JVChat.self, with: c.chatChange?.copy(knownArchived: true))
        }
    }
    
    private var e_agents: NSMutableSet {
        return mutableSetValue(forKeyPath: #keyPath(JVArchiveHitItem.m_agents))
    }
}

public final class JVArchiveHitChatItemGeneralChange: JVArchiveHitItemGeneralChange {
    public let type: String
    
    public override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_id", value: ID)
    }
    
    public init(ID: String,
         responseTimeout: Int,
         duration: Int,
         eventsNumber: Int,
         agentIDs: [Int],
         latestChatID: Int,
         chatChange: JVChatGeneralChange?,
         type: String) {
        self.type = type
        
        super.init(
            ID: ID,
            responseTimeout: responseTimeout,
            duration: duration,
            eventsNumber: eventsNumber,
            agentIDs: agentIDs,
            latestChatID: latestChatID,
            chatChange: chatChange
        )
    }
    
    required public init(json: JsonElement) {
        type = json["chat_type"].stringValue
        super.init(json: json)
    }
    
    public func copyUnrelative() -> JVArchiveHitChatItemGeneralChange {
        return JVArchiveHitChatItemGeneralChange(
            ID: ID,
            responseTimeout: responseTimeout,
            duration: duration,
            eventsNumber: eventsNumber,
            agentIDs: agentIDs,
            latestChatID: latestChatID,
            chatChange: chatChange?.copy(relation: "", everybody: true),
            type: type
        )
    }
}
