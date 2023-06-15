//
//  JVClient+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVClient {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = m_id
        }
        
        if let c = change as? JVClientGeneralChange {
            m_id = Int64(c.ID)
            m_guest_id = c.guestID.jv_valuable ?? m_guest_id
            m_chat_id = c.chatID?.jv_toInt64 ?? m_chat_id
            m_channel_id = Int64(c.channelID)
            m_channel_name = c.channelName ?? m_channel_name
            m_channel = context.object(JVChannel.self, primaryId: c.channelID)
            m_display_name = c.displayName ?? String()
            m_avatar_link = c.avatarURL ?? m_avatar_link
            m_comment = c.comment
            m_visits_number = c.visitsNumber?.jv_toInt16 ?? m_visits_number
            m_navigates_number = c.navigatesNumber?.jv_toInt16 ?? m_navigates_number
            m_active_session = context.upsert(m_active_session, with: c.activeSession)
            m_is_online = c.connectionLost?.jv_inverted() ?? m_is_online
            m_has_startup = c.hasStartup
            m_is_blocked = c.isBlocked
            
            if c.phoneByAgent == c.phoneByClient {
                m_phone_by_client = nil
                m_phone_by_agent = c.phoneByAgent.map(simplifyPhoneNumber)
            }
            else {
                m_phone_by_client = c.phoneByClient.map(simplifyPhoneNumber)
                m_phone_by_agent = c.phoneByAgent.map(simplifyPhoneNumber)
            }
            
            m_phones_extra = c.phonesExtra.map(simplifyPhoneNumber).filter { phone in
                if phone == m_phone_by_client { return false }
                if phone == m_phone_by_agent { return false }
                return true
            }.joined(separator: ";").jv_valuable
            
            if c.emailByAgent == c.emailByClient {
                m_email_by_client = nil
                m_email_by_agent = c.emailByAgent
            }
            else {
                m_email_by_client = c.emailByClient
                m_email_by_agent = c.emailByAgent
            }
            
            m_emails_extra = c.emailsExtra.filter { email in
                if email == m_email_by_client { return false }
                if email == m_email_by_agent { return false }
                return true
            }.joined(separator: ";").jv_valuable
            
            switch c.assignedAgentID {
            case .none:
                break
            case .some(0):
                m_assigned_agent = nil
            case .some(let agentID):
                m_assigned_agent = context.agent(for: agentID, provideDefault: true)
            }
            
            if let integration = c.integration ?? m_integration?.jv_valuable {
                m_integration = integration
                m_integration_link = c.socialLinks[integration]
            }
            else if let integration = c.socialLinks.keys.first {
                m_integration = integration
                m_integration_link = c.socialLinks[integration]
            }

            m_task = context.upsert(of: JVTask.self, with: c.task) ?? m_task
            
            if let customData = c.customData {
                e_custom_data.setSet(Set(context.insert(of: JVClientCustomField.self, with: customData)))
            }
        }
        else if let c = change as? JVClientGuestChange {
            m_id = Int64(c.ID)
            m_guest_id = c.guestID
        }
        else if let c = change as? JVClientShortChange {
            m_id = Int64(c.ID)
            m_guest_id = c.guestID
            m_display_name = c.displayName ?? String()
            m_avatar_link = c.avatarURL ?? m_avatar_link
            m_emails_extra = [c.email].jv_flatten().joined(separator: ";").jv_valuable

            if let channelID = c.channelID {
                m_channel_id = Int64(channelID)
                m_channel = context.object(JVChannel.self, primaryId: channelID)
            }

            switch c.assignedAgentID {
            case .none:
                break
            case .some(0):
                m_assigned_agent = nil
            case .some(let agentID):
                m_assigned_agent = context.agent(for: agentID, provideDefault: true)
            }
            
            m_task = context.upsert(of: JVTask.self, with: c.task) ?? m_task
        }
        else if let c = change as? JVClientOnlineChange {
            m_is_online = c.isOnline
        }
        else if let c = change as? JVClientHasActiveCallChange {
            m_has_active_call = c.hasCall
        }
        else if let c = change as? JVClientTaskChange {
            m_task = context.object(JVTask.self, primaryId: c.taskID)
        }
        else if let c = change as? JVClientBlockingChange {
            m_is_blocked = c.blocking
        }
        else if let c = change as? JVClientAssignedAgentChange {
            switch c.agentID {
            case .none:
                m_assigned_agent = nil
            case .some(let agentID):
                m_assigned_agent = context.agent(for: agentID, provideDefault: true)
            }
        }
        else if let _ = change as? JVClientResetChange {
            m_public_id = nil
            m_guest_id = nil
            m_display_name = nil
            m_avatar_link = nil
            
            m_channel_id = 0
            m_channel = nil

            m_assigned_agent = nil
            m_task = nil
        }
    }
    
    private var e_custom_data: NSMutableSet {
        return mutableSetValue(forKeyPath: #keyPath(JVClient.m_custom_data))
    }
    
    private func simplifyPhoneNumber(_ phone: String) -> String {
        let badSymbols = NSCharacterSet(charactersIn: "+0123456789").inverted
        return phone.components(separatedBy: badSymbols).joined()
    }
}

final class JVClientGeneralChange: JVDatabaseModelChange {
    public let ID: Int
    public let guestID: String
    public let chatID: Int?
    public let channelID: Int
    public let channelName: String?
    public let displayName: String?
    public let avatarURL: String?
    public let emailByClient: String?
    public let emailByAgent: String?
    public let emailsExtra: [String]
    public let phoneByClient: String?
    public let phoneByAgent: String?
    public let phonesExtra: [String]
    public let comment: String?
    public let visitsNumber: Int?
    public let navigatesNumber: Int?
    public let assignedAgentID: Int?
    public let activeSession: JVClientSessionGeneralChange?
    public let socialLinks: [String: String]
    public let integration: String?
    public let connectionLost: Bool?
    public let hasStartup: Bool
    public let task: JVTaskGeneralChange?
    public let customData: [JVClientCustomDataGeneralChange]?
    public let isBlocked: Bool

    override var primaryValue: Int {
        return ID
    }
    
    override var isValid: Bool {
        guard ID > 0 else { return false }
        return true
    }
    
    init(clientID: Int) {
        ID = clientID
        guestID = String()
        chatID = nil
        channelID = 0
        channelName = nil
        displayName = nil
        avatarURL = nil
        emailByClient = nil
        emailByAgent = nil
        emailsExtra = .jv_empty
        phoneByClient = nil
        phoneByAgent = nil
        phonesExtra = .jv_empty
        comment = nil
        visitsNumber = nil
        assignedAgentID = nil
        navigatesNumber = nil
        activeSession = nil
        socialLinks = [:]
        integration = nil
        connectionLost = nil
        hasStartup = true
        task = nil
        customData = nil
        isBlocked = false
        super.init()
    }
    
    required init(json: JsonElement) {
        func _parseSocialLinks(source: JsonElement) -> [String: String] {
            var links = [String: String]()
            
            let replaceTypes: [String: String] = [
                "vkontakte": "vk",
                "facebook": "fb"
            ]
            
            source["social_profiles"].arrayValue.forEach { social in
                let type = social["type_name"].stringValue
                let link = social["url"].stringValue
                links[replaceTypes[type] ?? type] = link
            }
            
            source["socialProfiles"].arrayValue.forEach { social in
                let type = social["typeName"].stringValue
                let link = social["url"].stringValue
                links[replaceTypes[type] ?? type] = link
            }
            
            return links
        }
        
        if let ci = json.has(key: "client_info") {
            ID = ci["client_id"].int ?? json["client_id"].intValue
            guestID = ci["visitor_id"].string ?? json["visitor_id"].stringValue
            displayName = ci["agent_client_name"].valuable ?? ci["client_name"].valuable ?? ci["display_name"].valuable
            avatarURL = ci["avatar_url"].valuable
            emailByClient = ci["email"].valuable
            emailByAgent = ci["agent_client_email"].valuable
            emailsExtra = ci["contacts"].arrayValue.filter({ $0["contact_type"].string == "email" }).compactMap({ $0["contact"].string })
            phoneByClient = ci["phone"].valuable
            phoneByAgent = ci["agent_client_phone"].valuable
            phonesExtra = ci["contacts"].arrayValue.filter({ $0["contact_type"].string == "phone" }).compactMap({ $0["contact"].string })
            comment = ci["description"].valuable
            visitsNumber = json["visits_count"].int
            assignedAgentID = ci["assigned_agent_id"].int
            navigatesNumber = json["navigated_count"].int
            activeSession = ci.parse()
            socialLinks = [:]
            customData = ci["custom_data"].parseList()
            hasStartup = (json["startup_seconds"].int != nil)
        }
        else {
            ID = json["client_id"].intValue
            guestID = json["visitor_id"].stringValue
            displayName = json["agent_client_name"].valuable ?? json["client_name"].valuable ?? json["display_name"].valuable
            avatarURL = json["avatar_url"].valuable
            emailByClient = json["email"].valuable
            emailByAgent = json["agent_client_email"].valuable
            emailsExtra = json["contacts"].arrayValue.filter({ $0["contact_type"].string == "email" }).compactMap({ $0["contact"].string })
            phoneByClient = json["phone"].valuable
            phoneByAgent = json["agent_client_phone"].valuable
            phonesExtra = json["contacts"].arrayValue.filter({ $0["contact_type"].string == "phone" }).compactMap({ $0["contact"].string })
            comment = json["description"].valuable
            visitsNumber = json["visits_count"].int
            assignedAgentID = json["assigned_agent_id"].int
            navigatesNumber = json["navigated_count"].int
            activeSession = json["sessions"].arrayValue.first?.parse()
            socialLinks = _parseSocialLinks(source: json["social"])
            customData = json["custom_data"].parseList()
            hasStartup = true
        }
        
        chatID = json["chat_id"].int
        channelID = json["widget_id"].intValue
        channelName = json["widget_name"].string
        integration = json["has_integration"].string
        
        if let value = json["connection_lost"].int {
            connectionLost = (value > 0)
        }
        else {
            connectionLost = nil
        }

        task = json["reminder"].parse()
        isBlocked = (json.has(key: "blacklist") != nil)

        super.init(json: json)
    }
}

final class JVClientTypingChange: JVDatabaseModelChange {
    public let ID: Int
    public let chatID: Int
    public let input: String?

    override var primaryValue: Int {
        return ID
    }
    
    init(ID: Int, chatID: Int, input: String?) {
        self.ID = ID
        self.chatID = chatID
        self.input = input
        super.init()
    }

    required init(json: JsonElement) {
        ID = json["client_id"].intValue
        chatID = json["chat_id"].intValue

        if let typing = json["typing"].int {
            input = (typing > 0 ? json["new_val"].stringValue : nil)
        }
        else {
            input = json["new_val"].stringValue.jv_valuable
        }

        super.init(json: json)
    }

    func copy(input: String?) -> JVClientTypingChange {
        return JVClientTypingChange(ID: ID, chatID: chatID, input: input)
    }

    func copyWithoutInput() -> JVClientTypingChange {
        return JVClientTypingChange(ID: ID, chatID: chatID, input: nil)
    }
}

final class JVClientUTMChange: JVDatabaseModelChange {
    public let ID: Int
    public let UTM: JVClientSessionUTMGeneralChange?
    
    override var primaryValue: Int {
        return ID
    }
    
    required init(json: JsonElement) {
        ID = json["client_id"].intValue
        UTM = json["client_info"].parse()
        super.init(json: json)
    }
}

final class JVClientGuestChange: JVDatabaseModelChange {
    public let ID: Int
    public let guestID: String
    
    override var primaryValue: Int {
        return ID
    }
    
    init(ID: Int, guestID: String) {
        self.ID = ID
        self.guestID = guestID
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

final class JVClientShortChange: JVDatabaseModelChange, NSCoding {
    public let ID: Int
    public let guestID: String
    public let channelID: Int?
    public let displayName: String?
    public let avatarURL: String?
    public let email: String?
    public let task: JVTaskGeneralChange?
    public let assignedAgentID: Int?

    private let codableIdKey = "id"
    private let codableGuestKey = "visitor"
    private let codableChannelKey = "channel"
    private let codableNameKey = "name"
    private let codableAvatarKey = "avatar"
    private let codableEmailKey = "name"
    private let codableTaskKey = "reminder"
    private let codableAssignedAgentKey = "assigned_agent"

    override var primaryValue: Int {
        return ID
    }
    
    override var isValid: Bool {
        return (ID > 0)
    }
    
    required init(json: JsonElement) {
        ID = json["client_id"].intValue
        guestID = json["visitor_id"].stringValue
        channelID = json["widget_id"].int
        displayName = json["agent_client_name"].valuable ?? json["client_name"].valuable ?? json["display_name"].valuable
        avatarURL = json["avatar_url"].valuable
        email = json["email"].string
        task = json["reminder"].parse()
        assignedAgentID = json["assigned_agent_id"].int
        super.init(json: json)
    }
    
    init(ID: Int, channelID: Int?, task: JVTaskGeneralChange?) {
        self.ID = ID
        self.guestID = String()
        self.channelID = channelID
        self.displayName = nil
        self.avatarURL = nil
        self.email = nil
        self.task = task
        self.assignedAgentID = 0
        super.init()
    }
    
    init?(coder: NSCoder) {
        ID = coder.decodeInteger(forKey: codableIdKey)
        guestID = (coder.decodeObject(forKey: codableGuestKey) as? String) ?? String()
        channelID = coder.decodeObject(forKey: codableChannelKey) as? Int
        displayName = coder.decodeObject(forKey: codableNameKey) as? String
        avatarURL = coder.decodeObject(forKey: codableAvatarKey) as? String
        email = coder.decodeObject(forKey: codableEmailKey) as? String
        task = coder.decodeObject(of: JVTaskGeneralChange.self, forKey: codableTaskKey)
        assignedAgentID = coder.decodeObject(of: NSNumber.self, forKey: codableAssignedAgentKey)?.intValue
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(ID, forKey: codableIdKey)
        coder.encode(guestID, forKey: codableGuestKey)
        coder.encode(channelID, forKey: codableChannelKey)
        coder.encode(displayName, forKey: codableNameKey)
        coder.encode(avatarURL, forKey: codableAvatarKey)
        coder.encode(email, forKey: codableEmailKey)
        coder.encode(task, forKey: codableTaskKey)
        coder.encode(assignedAgentID.flatMap(NSNumber.init), forKey: codableAssignedAgentKey)
    }
}

final class JVClientHistoryChange: JVDatabaseModelChange {
    private(set) var messages = [JVMessageGeneralChange]()
    private(set) var loadedEntirely: Bool = false
    
    init(json: JsonElement, loadedEntirely: Bool) {
        super.init(json: json)
        self.loadedEntirely = loadedEntirely
        messages = json["messages"].parseList() ?? []
    }
    
    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

final class JVClientOnlineChange: JVDatabaseModelChange {
    public let ID: Int
    public let isOnline: Bool
    
    override var primaryValue: Int {
        return ID
    }
    
    init(ID: Int, isOnline: Bool) {
        self.ID = ID
        self.isOnline = isOnline
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

final class JVClientInaliveChange: JVDatabaseModelChange {
    public let ID: Int
    
    override var primaryValue: Int {
        return ID
    }
    
    required init(json: JsonElement) {
        ID = json["client_id"].intValue
        super.init()
    }
}

final class JVClientHasActiveCallChange: JVDatabaseModelChange {
    public let ID: Int
    public let hasCall: Bool
    
    override var primaryValue: Int {
        return ID
    }
    
    init(ID: Int, hasCall: Bool) {
        self.ID = ID
        self.hasCall = hasCall
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

final class JVClientTaskChange: JVDatabaseModelChange {
    public let ID: Int
    public let taskID: Int

    override var primaryValue: Int {
        return ID
    }
    
    init(ID: Int, taskID: Int) {
        self.ID = ID
        self.taskID = taskID
        super.init()
    }

    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

final class JVClientBlockingChange: JVDatabaseModelChange {
    public let ID: Int
    public let blocking: Bool

    override var primaryValue: Int {
        return ID
    }
    
    init(ID: Int, blocking: Bool) {
        self.ID = ID
        self.blocking = blocking
        super.init()
    }

    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

final class JVClientAssignedAgentChange: JVDatabaseModelChange {
    public let ID: Int
    public let agentID: Int?

    override var primaryValue: Int {
        return ID
    }
    
    init(ID: Int, agentID: Int?) {
        self.ID = ID
        self.agentID = agentID
        super.init()
    }

    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

final class JVClientResetChange: JVDatabaseModelChange {
    public let ID: Int
    
    override var primaryValue: Int {
        return ID
    }
    
    init(ID: Int) {
        self.ID = ID
        super.init()
    }

    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

fileprivate func simplifyPhoneNumber(_ phone: String) -> String {
    let badSymbols = NSCharacterSet(charactersIn: "+0123456789").inverted
    return phone.components(separatedBy: badSymbols).joined()
}
