//
//  JVCall+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVCall {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = m_id
        }
        
        if let c = change as? JVCallGeneralChange {
            m_id = Int64(c.ID)
        }
    }
}

public final class JVCallGeneralChange: JVDatabaseModelChange {
    public let ID: Int
    
    public override var primaryValue: Int {
        return ID
    }
    
    required public init(json: JsonElement) {
        ID = json["msg_id"].intValue
        super.init(json: json)
    }
}

public final class JVCallLiveChange: JVDatabaseModelChange {
    public let ID: String
    public let phone: String
    public let agentID: Int
    public let chatID: Int
    public let type: JVMessageBodyCallType
    public let clientID: Int
    public let channelId: Int?
    public let event: JVMessageBodyCallEvent
    public let clientConnected: Bool
    public let reason: String?

    required public init(json: JsonElement) {
        ID = json["call_id"].stringValue
        phone = json["phone"].stringValue
        agentID = json["agent_id"].intValue
        chatID = json["chat_id"].intValue
        type = JVMessageBodyCallType(rawValue: json["type"].stringValue) ?? .unknown
        clientID = json["client_id"].intValue
        channelId = json["widget_id"].int
        event = JVMessageBodyCallEvent(rawValue: json["status"].stringValue) ?? .unknown
        clientConnected = json["client_connected"].boolValue
        reason = json["reason"].string
        super.init(json: json)
    }
}
