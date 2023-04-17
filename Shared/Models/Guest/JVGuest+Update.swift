//
//  JVGuest+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVGuest {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_str = m_id
        }
        
        if let c = change as? JVGuestBaseChange {
            if m_id == String() { m_id = c.ID }
            if m_agent_id == 0 { m_agent_id = abs(c.agentID?.jv_toInt64 ?? m_agent_id) }
            if m_start_date == nil { m_start_date = Date() }
            if jv_not(c.siteID.isEmpty) { m_channel_id = c.siteID }
        }
        
        if jv_not(change is JVGuestRemovalChange) {
            m_last_update = Date()
            m_disappear_date = nil
        }
        
        if let c = change as? JVGuestGeneralChange {
            m_source_ip = c.sourceIP
            m_source_port = c.sourcePort.jv_toInt32
            m_region_code = c.regionCode.jv_toInt16
            m_country_code = c.countryCode
            m_country_name = c.countryName
            m_region_name = c.regionName
            m_city_name = c.cityName
            m_organization = c.organization
        }
        else if let c = change as? JVGuestClientChange {
            m_client_id = c.clientID.jv_toInt64
        }
        else if let c = change as? JVGuestNameChange {
            m_name = c.name
        }
        else if let c = change as? JVGuestProactiveChange {
            m_proactive_agent = context.agent(for: c.proactiveAgentID, provideDefault: true)
        }
        else if let c = change as? JVGuestStatusChange {
            m_status = c.status
        }
        else if let c = change as? JVGuestPageLinkChange {
            m_page_link = c.link
        }
        else if let c = change as? JVGuestPageTitleChange {
            m_page_title = c.title
        }
        else if let c = change as? JVGuestStartTimeChange {
            m_start_date = Date().addingTimeInterval(-c.timestamp)
        }
        else if let c = change as? GuestUTMChange {
            m_utm = context.insert(of: JVClientSessionUtm.self, with: c.utm)
        }
        else if let c = change as? JVGuestVisitsChange {
            m_visits_number = c.number.jv_toInt16
        }
        else if let c = change as? JVGuestNavigatesChange {
            m_navigates_number = c.number.jv_toInt16
        }
        else if let c = change as? JVGuestVisibleChange {
            m_visible = c.value
        }
        else if let c = change as? JVGuestAgentsChange {
            let attendees = c.agentIDs.map {
                JVChatAttendeeGeneralChange(
                    ID: $0,
                    relation: "attendee",
                    comment: nil,
                    invitedBy: nil,
                    isAssistant: false,
                    receivedMessageID: 0,
                    unreadNumber: 0,
                    notifications: nil
                )
            }
            
            e_attendees.setSet(Set(context.insert(of: JVChatAttendee.self, with: attendees)))
        }
        else if let c = change as? JVGuestBotsChange {
            let bots = c.botsIds.compactMap { context.bot(for: $0, provideDefault: true) }
            e_bots.setSet(Set(bots))
        }
        else if let c = change as? JVGuestWidgetVersionChange {
            m_widget_version = c.version
        }
        else if let _ = change as? JVGuestUpdateChange {
            m_last_update = Date()
        }
        else if let _ = change as? JVGuestRemovalChange {
            m_disappear_date = Date()
        }
    }
    
    private var e_attendees: NSMutableSet {
        return mutableSetValue(forKeyPath: #keyPath(JVGuest.m_attendees))
    }
    
    private var e_bots: NSMutableSet {
        return mutableSetValue(forKeyPath: #keyPath(JVGuest.m_bots))
    }
}

public func JVGuestChangeParse(for item: String) -> JVGuestBaseChange? {
    let args = item.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
    guard args.count >= 4 else { return nil }
    
    switch args[3] {
    case "+": return JVGuestGeneralChange(arguments: args)
    case "cid": return JVGuestClientChange(arguments: args)
    case "name": return JVGuestNameChange(arguments: args)
    case "status": return JVGuestStatusChange(arguments: args)
    case "pa_id": return JVGuestProactiveChange(arguments: args)
    case "purl": return JVGuestPageLinkChange(arguments: args)
    case "ptitle": return JVGuestPageTitleChange(arguments: args)
    case "startsec": return JVGuestStartTimeChange(arguments: args)
    case "utm": return GuestUTMChange(arguments: args)
    case "visits": return JVGuestVisitsChange(arguments: args)
    case "navcount": return JVGuestNavigatesChange(arguments: args)
    case "visible": return JVGuestVisibleChange(arguments: args)
    case "agentids": return JVGuestAgentsChange(arguments: args)
    case "botids": return JVGuestBotsChange(arguments: args)
    case "wversion": return JVGuestWidgetVersionChange(arguments: args)
    case "-": return JVGuestRemovalChange(arguments: args)
    default: return nil
    }
}

open class JVGuestBaseChange: JVDatabaseModelChange {
    public let ID: String
    public let siteID: String
    public let agentID: Int?
    
    open override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_id", value: ID)
    }
    
    public init(ID: String) {
        self.ID = ID
        self.siteID = String()
        self.agentID = nil
        super.init()
    }
    
    public init(arguments: [String]) {
        ID = arguments.jv_stringOrEmpty(at: 0)
        siteID = arguments.jv_stringOrEmpty(at: 1)
        agentID = arguments.jv_stringOrEmpty(at: 2).jv_toInt()
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
    
    open override var isValid: Bool {
        guard !ID.isEmpty else { return false }
        guard !siteID.isEmpty else { return false }
        return true
    }
}

open class JVGuestGeneralChange: JVGuestBaseChange {
    public let sourceIP: String
    public let sourcePort: Int
    public let regionCode: Int
    public let countryCode: String
    public let countryName: String
    public let regionName: String
    public let cityName: String
    public let organization: String
    
    override init(arguments: [String]) {
        sourceIP = arguments.jv_stringOrEmpty(at: 4)
        sourcePort = arguments.jv_stringOrEmpty(at: 5).jv_toInt()
        regionCode = arguments.jv_stringOrEmpty(at: 6).jv_toInt()
        countryCode = arguments.jv_stringOrEmpty(at: 7)
        countryName = arguments.jv_stringOrEmpty(at: 8)
        regionName = arguments.jv_stringOrEmpty(at: 9)
        cityName = arguments.jv_stringOrEmpty(at: 10)
        organization = arguments.jv_stringOrEmpty(at: 13)
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestClientChange: JVGuestBaseChange {
    public let clientID: Int

    override init(arguments: [String]) {
        clientID = arguments.jv_stringOrEmpty(at: 4).jv_toInt()
        super.init(arguments: arguments)
    }

    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestStatusChange: JVGuestBaseChange {
    public let status: String
    
    override init(arguments: [String]) {
        status = arguments.jv_stringOrEmpty(at: 4)
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestProactiveChange: JVGuestBaseChange {
    public let proactiveAgentID: Int
    
    override init(arguments: [String]) {
        proactiveAgentID = arguments.jv_stringOrEmpty(at: 4).jv_toInt()
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestNameChange: JVGuestBaseChange {
    public let name: String
    
    override init(arguments: [String]) {
        name = arguments.jv_stringOrEmpty(at: 4)
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestPageLinkChange: JVGuestBaseChange {
    public let link: String
    
    override init(arguments: [String]) {
        link = arguments.jv_stringOrEmpty(at: 4)
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestPageTitleChange: JVGuestBaseChange {
    public let title: String
    
    override init(arguments: [String]) {
        title = arguments.jv_stringOrEmpty(at: 4)
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestStartTimeChange: JVGuestBaseChange {
    public let timestamp: TimeInterval
    
    override init(arguments: [String]) {
        timestamp = TimeInterval(arguments.jv_stringOrEmpty(at: 4).jv_toInt())
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class GuestUTMChange: JVGuestBaseChange {
    private static var jsonCoder = JsonCoder()
    
    public let utm: JVClientSessionUTMGeneralChange?
    
    override init(arguments: [String]) {
        utm = GuestUTMChange.jsonCoder.decode(raw: arguments.jv_stringOrEmpty(at: 4))?.parse()
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestVisitsChange: JVGuestBaseChange {
    public let number: Int
    
    override init(arguments: [String]) {
        number = arguments.jv_stringOrEmpty(at: 4).jv_toInt()
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestNavigatesChange: JVGuestBaseChange {
    public let number: Int
    
    override init(arguments: [String]) {
        number = arguments.jv_stringOrEmpty(at: 4).jv_toInt()
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestVisibleChange: JVGuestBaseChange {
    public let value: Bool
    
    override init(arguments: [String]) {
        value = arguments.jv_stringOrEmpty(at: 4).jv_toBool()
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestAgentsChange: JVGuestBaseChange {
    private static var jsonCoder = JsonCoder()
    
    public let agentIDs: [Int]
    
    override init(arguments: [String]) {
        let idsArgument = arguments.jv_stringOrEmpty(at: 4)
        
        let idsSource: String
        if idsArgument.hasPrefix("[") {
            idsSource = idsArgument
        }
        else if idsArgument == "false" {
            idsSource = "[]"
        }
        else {
            idsSource = "[\(idsArgument)]"
        }
        
        agentIDs = JVGuestAgentsChange.jsonCoder.decode(raw: idsSource)?.intArray ?? []
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestBotsChange: JVGuestBaseChange {
    private static var jsonCoder = JsonCoder()
    
    public let botsIds: [Int]
    
    override init(arguments: [String]) {
        let idsArgument = arguments.jv_stringOrEmpty(at: 4)
        
        let idsSource: String
        if idsArgument.hasPrefix("[") {
            idsSource = idsArgument
        }
        else if idsArgument == "false" {
            idsSource = "[]"
        }
        else {
            idsSource = "[\(idsArgument)]"
        }
        
        botsIds = JVGuestBotsChange.jsonCoder.decode(raw: idsSource)?.intArray ?? []
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVGuestWidgetVersionChange: JVGuestBaseChange {
    public let version: String
    
    override init(arguments: [String]) {
        version = arguments.jv_stringOrEmpty(at: 4)
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVGuestUpdateChange: JVGuestBaseChange {
}

open class JVGuestRemovalChange: JVGuestBaseChange {
    override init(arguments: [String]) {
        super.init(arguments: arguments)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}
