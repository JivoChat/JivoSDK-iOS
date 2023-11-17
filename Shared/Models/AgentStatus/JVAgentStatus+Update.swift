//
//  JVAgentStatus+Update.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVAgentStatus {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = Int64(m_id)
        }
        
        if let c = change as? JVAgentStatusGeneralChange {
            m_id = Int16(c.statusID)
            m_title = c.title
            m_emoji = c.emoji
            m_position = (c.position > 0 ? Int16(c.position) : m_position)
        }
    }
}

final class JVAgentStatusGeneralChange: JVDatabaseModelChange, Codable {
    public let statusID: Int
    public let title: String
    public let emoji: String
    public let position: Int
    
    override var primaryValue: Int {
        return statusID
    }
    
    override var isValid: Bool {
        return (statusID > 0)
    }
    
    required init(json: JsonElement) {
        statusID = json["agent_status_id"].intValue
        title = json["title"].stringValue
        position = json["position"].intValue
        emoji = json["emoji"].stringValue
        super.init(json: json)
    }
}

enum JVAgentLicensedFeature: Int {
    case blacklist
    case geoip
    case phrases
    case transfer
    case invite
    case away
    case typing
    case info
    case files
    
    func resolveBit(within raw: Int) -> Bool {
        return (raw & (1 << rawValue)) > 0
    }
}

final class JVAgentSessionGeneralChange: JVDatabaseModelChange, Codable {
    var sessionID: String
    var email: String
    var siteID: Int
    var isOwner: Bool
    var isAdmin: Bool
    var isSupervisor: Bool
    var isOperator: Bool
    var voxLogin: String
    var voxPassword: String
    var mobileCalls: Bool
    var workingState: Bool
    
    override var primaryValue: Int {
        return siteID
    }
    
    override var isValid: Bool {
        guard let _ = sessionID.jv_valuable else { return false }
        return true
    }
    
    required init(json: JsonElement) {
        sessionID = json["agent_info"]["agent_session_id"].string ?? json["jv_sess_id"].stringValue
        email = json["agent_info"]["email"].stringValue
        isOwner = json["agent_info"]["is_owner"].boolValue
        isAdmin = json["agent_info"]["is_admin"].boolValue
        isSupervisor = json["agent_info"]["is_supervisor"].bool ?? false
        isOperator = json["agent_info"]["is_operator"].bool ?? true
        siteID = json["agent_info"]["site_id"].intValue
        voxLogin = json["agent_info"]["vox_name"].stringValue
        voxPassword = json["agent_info"]["vox_password"].stringValue
        mobileCalls = json["agent_info"]["calls_mobile"].boolValue
        workingState = ((json["agent_info"]["work_state"].int ?? 1) > 0)
        super.init(json: json)
    }
}

final class JVAgentSessionContextChange: JVDatabaseModelChange {
    public let scanned: Bool
    public let widgetPublicID: String?
    public let agentsJSON: JsonElement?
    public let agents: [JVAgentGeneralChange]?
    public let clients: [JVClientGeneralChange]?
    public let currency: String?
    public let pricelistID: Int?
    public let licenseLimit: Int?

    override var isValid: Bool {
        return scanned
    }
    
    required init(json: JsonElement) {
        if let context = json.has(key: "rmo_context") {
            scanned = true
            
            widgetPublicID = context["sites"].arrayValue.first?["public_id"].string
            agentsJSON = context.has(key: "agents")
            
            agents = agentsJSON?.parseList()
            clients = context["clients"].parseList()
            
            if let misc = context.has(key: "misc") {
                currency = misc["currency"].string
                pricelistID = misc["pricelist_id"].int
                licenseLimit = misc["license_limit"].int
            }
            else {
                currency = nil
                pricelistID = nil
                licenseLimit = nil
            }
        }
        else {
            scanned = false
            widgetPublicID = nil
            agentsJSON = JsonElement()
            agents = []
            clients = []
            currency = nil
            pricelistID = nil
            licenseLimit = nil
        }
        
        super.init(json: json)
    }
}

final class JVAgentSessionBoxesChange: JVDatabaseModelChange {
    public let source: JsonElement
    public let chats: [JVChatGeneralChange]
    
    required init(json: JsonElement) {
        source = json
        chats = json["chats"].parseList() ?? []
        super.init(json: json)
    }
    
    init(source: JsonElement, chats: [JVChatGeneralChange]) {
        self.source = source
        self.chats = chats
        super.init()
    }

    func extractClientChats() -> [JVChatGeneralChange] {
        return chats.filter { $0.client != nil }
    }

    func extractTeamChats() -> [JVChatGeneralChange] {
        return chats.filter { !($0.isGroup == true) && $0.client == nil }
    }
    
    func extractGroupChats() -> [JVChatGeneralChange] {
        return chats.filter { ($0.isGroup == true) }
    }
    
    func extractChatIDs() -> [Int] {
        return chats.map { $0.ID }
    }
    
    var cachable: JVAgentSessionBoxesChange {
        return JVAgentSessionBoxesChange(
            source: source,
            chats: chats.map(\.cachable)
        )
    }
}

final class JVAgentSessionActivityChange: JVDatabaseModelChange {
    public let isActive: Bool
        init(isActive: Bool) {
        self.isActive = isActive
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

final class JVAgentSessionMobileCallsChange: JVDatabaseModelChange {
    public let enabled: Bool
    
    init(enabled: Bool) {
        self.enabled = enabled
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

final class JVAgentSessionWorktimeChange: JVDatabaseModelChange {
    public let agentID: Int?
    public let isWorking: Bool?
    public let isWorkingHidden: Bool
    
    init(isWorking: Bool?, isWorkingHidden: Bool) {
        self.agentID = nil
        self.isWorking = isWorking
        self.isWorkingHidden = isWorkingHidden
        super.init()
    }
    
    required init(json: JsonElement) {
        agentID = json["agent_id"].int
        isWorking = json["work_state"].int.flatMap { $0 > 0 }
        isWorkingHidden = false
        super.init(json: json)
    }
}

final class JVAgentSessionChannelsChange: JVDatabaseModelChange {
    public let channels: [JVChannelGeneralChange]
    
    init(channels: [JVChannelGeneralChange]) {
        self.channels = channels
        super.init()
    }
    
    required init(json: JsonElement) {
        channels = []
        super.init(json: json)
    }
}

final class JVAgentSessionChannelUpdateChange: JVDatabaseModelChange {
    public let channel: JVChannelGeneralChange
    
    init(channel: JVChannelGeneralChange) {
        self.channel = channel
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError()
    }
}

final class JVAgentSessionChannelRemoveChange: JVDatabaseModelChange {
    public let channelId: Int
    
    init(channelId: Int) {
        self.channelId = channelId
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError()
    }
}

func JVAgentSessionParseFeatures(source: JsonElement) -> Int {
    func _bit(key: String, flag: JVAgentLicensedFeature) -> Int {
        let value = source[key].boolValue ? 1 : 0
        return (value << flag.rawValue)
    }
    
    let flags: [Int] = [
        _bit(key: "blacklist", flag: .blacklist),
        _bit(key: "geoip", flag: .geoip),
        _bit(key: "canned", flag: .phrases),
        _bit(key: "redirect", flag: .transfer),
        _bit(key: "multiagents", flag: .invite),
        _bit(key: "away", flag: .away),
        _bit(key: "typing_insight", flag: .typing),
        _bit(key: "page_info", flag: .info),
        _bit(key: "file_transfer", flag: .files)
    ]
    
    return flags.reduce(0, +)
}
