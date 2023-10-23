//
//  JVArchiveHitCallItem+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVArchiveHitCallItem {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_str = m_id
        }
        
        if let c = change as? JVArchiveHitCallItemGeneralChange {
            m_id = c.ID
            m_type = c.type
            m_status = c.status
            m_response_timeout = c.responseTimeout.jv_toInt32(.standard)
            m_duration = c.duration.jv_toInt32(.standard)
            m_events_number = Int16(c.eventsNumber)
            m_cost = c.cost
            m_cost_currency = c.costCurrency
            e_agents.setSet(Set(c.agentIDs.compactMap { context.object(JVAgent.self, primaryId: $0) }))
            m_latest_chat_id = Int64(c.latestChatID)
            m_chat = context.upsert(of: JVChat.self, with: c.chatChange?.copy(knownArchived: true))
            m_call = context.upsert(of: JVCall.self, with: c.callChange)
        }
    }
    
    private var e_agents: NSMutableSet {
        return mutableSetValue(forKeyPath: #keyPath(JVArchiveHitItem.m_agents))
    }
}

final class JVArchiveHitCallItemGeneralChange: JVArchiveHitItemGeneralChange {
    public let type: String
    public let status: String
    public let cost: Float
    public let costCurrency: String
    public let callChange: JVCallGeneralChange?
    
    init(ID: String,
         responseTimeout: Int,
         duration: Int,
         eventsNumber: Int,
         agentIDs: [Int],
         latestChatID: Int,
         chatChange: JVChatGeneralChange?,
         type: String,
         status: String,
         cost: Float,
         costCurrency: String,
         callChange: JVCallGeneralChange?) {
        self.type = type
        self.status = status
        self.cost = cost
        self.costCurrency = costCurrency
        self.callChange = callChange
        
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
    
    override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_id", value: ID)
    }
    
    required init(json: JsonElement) {
        type = json["call_type"].stringValue
        status = json["call_status"].stringValue
        cost = json["cost"].floatValue
        costCurrency = json["cost_currency"].stringValue
        callChange = json["call"].parse()
        super.init(json: json)
    }
    
    func copyUnrelative() -> JVArchiveHitCallItemGeneralChange {
        return JVArchiveHitCallItemGeneralChange(
            ID: ID,
            responseTimeout: responseTimeout,
            duration: duration,
            eventsNumber: eventsNumber,
            agentIDs: agentIDs,
            latestChatID: latestChatID,
            chatChange: chatChange?.copy(relation: "", everybody: true),
            type: type,
            status: status,
            cost: cost,
            costCurrency: costCurrency,
            callChange: callChange
        )
    }
}
