//
//  JVTask+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVTask {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = m_id
        }
        
        if let c = change as? JVTaskGeneralChange {
            m_id = c.ID.jv_toInt64(.standard)
            m_site_id = c.siteID?.jv_toInt64(.standard) ?? 0
            m_client_id = c.clientID?.jv_toInt64(.standard) ?? 0
            m_client = c.client.flatMap { context.client(for: $0.ID, needsDefault: true) }
            m_agent = context.agent(for: c.agentID, provideDefault: true)
            m_text = c.text
            m_created_timestamp = c.createdTs ?? m_created_timestamp
            m_modified_timestamp = c.modifiedTs ?? m_modified_timestamp
            m_notify_timstamp = c.notifyTs
            m_status = c.status
        }
        else if let _ = change as? JVTaskCompleteChange {
            m_status = "completed"
        }
    }
}

final class JVTaskGeneralChange: JVDatabaseModelChange, NSCoding {
    public let ID: Int
    public let siteID: Int?
    public let clientID: Int?
    public let client: JVClientGeneralChange?
    public let agentID: Int
    public let agent: JVAgentGeneralChange?
    public let text: String
    public let createdTs: TimeInterval?
    public let modifiedTs: TimeInterval?
    public let notifyTs: TimeInterval
    public let status: String

    private let codableIdKey = "id"
    private let codableSiteKey = "site"
    private let codableClientIDKey = "client"
    private let codableClientKey = "client_object"
    private let codableAgentIDKey = "agent"
    private let codableAgentKey = "agent_object"
    private let codableTextKey = "text"
    private let codableCreatedKey = "created_ts"
    private let codableModifiedKey = "updated_ts"
    private let codableTimepointKey = "timepoint"
    private let codableStatusKey = "status"
    
    override var primaryValue: Int {
        return ID
    }
    
    override var isValid: Bool {
        guard ID > 0 else { return false }
        return true
    }
    
    init(ID: Int,
         agentID: Int,
         agent: JVAgentGeneralChange?,
         text: String,
         createdTs: TimeInterval?,
         modifiedTs: TimeInterval?,
         notifyTs: TimeInterval,
         status: String) {
        self.ID = ID
        self.siteID = nil
        self.clientID = nil
        self.client = nil
        self.agentID = agentID
        self.agent = agent
        self.text = text
        self.createdTs = createdTs
        self.modifiedTs = modifiedTs
        self.notifyTs = notifyTs
        self.status = status
        super.init()
    }

    required init(json: JsonElement) {
        ID = json["reminder_id"].intValue
        siteID = json["site_id"].int
        clientID = json["client_id"].int
        client = json["client"].parse()
        agentID = json["agent_id"].intValue
        agent = json["agent"].parse()
        text = json["text"].stringValue
        createdTs = json["created_ts"].double
        modifiedTs = json["updated_ts"].double
        notifyTs = TimeInterval(json["notify_ts"].doubleValue)
        status = json["status"].stringValue
        super.init(json: json)
    }
    
    init?(coder: NSCoder) {
        ID = coder.decodeInteger(forKey: codableIdKey)
        siteID = coder.decodeObject(forKey: codableSiteKey) as? Int
        clientID = coder.decodeObject(forKey: codableClientIDKey) as? Int
        client = coder.decodeObject(forKey: codableClientKey) as? JVClientGeneralChange
        agentID = coder.decodeInteger(forKey: codableAgentIDKey)
        agent = coder.decodeObject(forKey: codableAgentKey) as? JVAgentGeneralChange
        text = (coder.decodeObject(forKey: codableTextKey) as? String) ?? String()
        createdTs = coder.decodeObject(forKey: codableCreatedKey) as? Double
        modifiedTs = coder.decodeObject(forKey: codableModifiedKey) as? Double
        notifyTs = coder.decodeDouble(forKey: codableTimepointKey)
        status = (coder.decodeObject(forKey: codableStatusKey) as? String) ?? String()
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(ID, forKey: codableIdKey)
        coder.encode(siteID, forKey: codableSiteKey)
        coder.encode(clientID, forKey: codableClientIDKey)
        coder.encode(client, forKey: codableClientKey)
        coder.encode(agentID, forKey: codableAgentIDKey)
        coder.encode(agent, forKey: codableAgentKey)
        coder.encode(text, forKey: codableTextKey)
        coder.encode(createdTs, forKey: codableCreatedKey)
        coder.encode(modifiedTs, forKey: codableModifiedKey)
        coder.encode(notifyTs, forKey: codableTimepointKey)
        coder.encode(status, forKey: codableStatusKey)
    }
}

final class JVTaskCompleteChange: JVDatabaseModelChange {
    public let ID: Int

    override var primaryValue: Int {
        return ID
    }

    init(ID: Int) {
        self.ID = ID
        super.init()
    }

    public required init(json: JsonElement) {
        self.ID = 0
        super.init()
    }
}
