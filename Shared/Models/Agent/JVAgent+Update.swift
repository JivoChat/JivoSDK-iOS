//
//  JVAgent+Update.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

fileprivate var f_defaultDisplayName = String()
extension JVAgent {
    static func registerDefaultDisplayName(value: String) {
        f_defaultDisplayName = value
    }
}

extension JVAgent {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            if m_pk_num != m_id {
                m_pk_num = m_id
            }
        }
        
        if let c = change as? JVAgentGeneralChange {
            m_id = Int64(c.ID)
            m_email = c.email.jv_valuable ?? m_email
            m_email_verified = c.emailVerified ?? m_email_verified
            m_phone = c.phone ?? m_phone
            m_state_id = c.stateID?.jv_toInt16(.standard) ?? m_state_id
            m_status = context.upsert(of: JVAgentStatus.self, with: c.status)
            m_status_comment = c.statusComment
            m_avatar_link = c.avatarLink.jv_valuable
            m_display_name = c.displayName
            m_channels = c.channels
            m_is_owner = c.isOwner ?? m_is_owner
            m_is_admin = c.isAdmin
            m_is_supervisor = c.isSupervisor
            m_is_operator = c.isOperator
            m_calling_destination = (c.callingDestination > -1 ? Int16(c.callingDestination) : m_calling_destination)
            m_calling_options = Int16(c.callingOptions)
            m_title = c.title
            m_worktime = context.upsert(of: JVAgentWorktime.self, with: c.worktime)
            m_is_working = c.isWorking ?? m_is_working
            m_session = context.upsert(of: JVAgentSession.self, with: c.session) ?? m_session
            m_has_session = (m_session != nil)
            
            m_ordering_name = c.displayName
            adjustOrderingGroup()
        }
        else if let c = change as? JVAgentWorktimeChange {
            m_worktime = context.upsert(of: JVAgentWorktime.self, with: c.worktimeChange)
        }
        else if let c = change as? JVAgentShortChange {
            m_id = Int64(c.ID)
            m_email = c.email ?? m_email
            m_display_name = c.displayName
            
            m_ordering_name = c.displayName
        }
        else if let c = change as? JVAgentSdkChange {
            m_id = Int64(c.id)
            m_display_name = c.displayName
            m_avatar_link = c.avatarLink
            m_title = c.title ?? m_title
        }
        else if let c = change as? JVAgentStateChange {
            m_state_id = Int16(c.state)
            
            adjustOrderingGroup()
        }
        else if let c = change as? JVAgentLastMessageChange {
            if let key = c.messageGlobalKey {
                let customId = JVDatabaseModelCustomId(key: key.key, value: key.value)
                m_last_message = context.object(JVMessage.self, customId: customId)
            }
            else if let key = c.messageLocalKey {
                let customId = JVDatabaseModelCustomId(key: key.key, value: key.value)
                m_last_message = context.object(JVMessage.self, customId: customId)
            }
            
            m_last_message_date = m_last_message?.date
        }
        else if let c = change as? JVAgentChatChange {
            m_chat = context.object(JVChat.self, primaryId: c.chatID)
            m_last_message_date = m_chat?.lastMessage?.date
        }
        else if let c = change as? JVAgentDraftChange {
            m_draft = c.draft
        }
        else if let c = change as? SDKAgentAtomChange {
            let m_id_val = Int64(c.id)
            if m_id != m_id_val {
                m_id = m_id_val
            }
            
            c.updates.forEach { update in
                switch update {
                case .displayName(let value):
                    if m_display_name != value {
                        m_display_name = value
                    }
                    
                case .title(let value):
                    if m_title != value {
                        m_title = value
                    }
                    
                case .avatarLink(let value):
                    let m_avatar_link_value = value?.absoluteString
                    if m_avatar_link != m_avatar_link_value {
                        m_avatar_link = m_avatar_link_value
                    }
                    
                case .status(let value):
                    let m_state_id_value = Int16(value.rawValue)
                    if m_state_id != m_state_id_value {
                        m_state_id = m_state_id_value
                    }
                }
            }
        }
    }
    
    private func adjustOrderingGroup() {
        switch JVAgentState(rawValue: Int(m_state_id)) ?? .none {
        case .none:
            m_ordering_group = Int16(JVAgentOrderingGroup.offline.rawValue)
        case .away where jv_not(m_is_working):
            m_ordering_group = Int16(JVAgentOrderingGroup.awayZZ.rawValue)
        case .away:
            m_ordering_group = Int16(JVAgentOrderingGroup.away.rawValue)
        case .active where jv_not(m_is_working):
            m_ordering_group = Int16(JVAgentOrderingGroup.onlineZZ.rawValue)
        case .active:
            m_ordering_group = Int16(JVAgentOrderingGroup.online.rawValue)
        }
    }
}

final class JVAgentGeneralChange: JVDatabaseModelChange, Codable {
    public let json: JsonElement
    public let isMe: Bool
    var ID: Int = 0
    var siteID: Int
    var email: String
    var emailVerified: Bool?
    var phone: String?
    var stateID: Int?
    var status: JVAgentStatusGeneralChange?
    var statusComment: String = ""
    var avatarLink: String
    var displayName: String = ""
    var title: String = ""
    var callingDestination: Int
    var callingOptions = 0
    public var channels: String = ""
    public let isOwner: Bool?
    public let isAdmin: Bool
    public let isSupervisor: Bool
    public let isOperator: Bool
    public let isWorking: Bool?
    public let session: JVAgentSessionGeneralChange?
    public let worktime: JVAgentWorktimeGeneralChange?

    override var primaryValue: Int {
        return ID
    }
    
    init(json: JsonElement, isMe: Bool) {
        self.json = json
        self.isMe = isMe
        
        let agentInfo = json.has(key: "agent_info") ?? json
        let flags: [Int] = [
            json["rmo_state"]["available_for_calls"] --> .availableForCalls,
            json["rmo_state"]["available_for_mobile_calls"] --> .availableForMobileCalls,
            json["rmo_state"]["on_call"] --> .onCall,
            json["calls_away"] --> .supportsAway,
            json["calls_offline"] --> .supportsOffline
        ]
        
        ID = agentInfo["agent_id"].intValue
        siteID = agentInfo["site_id"].intValue
        email = agentInfo["email"].stringValue
        emailVerified = agentInfo["email_verified"].bool
        phone = agentInfo["agent_phone"].string?.jv_valuable
        stateID = agentInfo["agent_state_id"].int
        status = agentInfo["agent_status"].parse()
        statusComment = agentInfo["agent_status"]["comment"].stringValue
        avatarLink = agentInfo["avatar_url"].stringValue
        displayName = agentInfo["display_name"].stringValue
        title = agentInfo["title"].stringValue
        callingDestination = agentInfo["web_call_dest"].int ?? -1
        callingOptions = flags.reduce(0, +)
        channels = agentInfo["channels"].array?.description ?? ""
        isOwner = agentInfo["is_owner"].bool
        isAdmin = agentInfo["is_admin"].bool ?? true
        isSupervisor = agentInfo["is_supervisor"].bool ?? true
        isOperator = agentInfo["is_operator"].bool ?? true
        isWorking = agentInfo["work_state"].int.flatMap { $0 > 0 }
        session = json.parse()
        worktime = json.parse()
        
        super.init(json: json)
    }
    
    init(placeholderID: Int) {
        json = JsonElement()
        isMe = false
        ID = placeholderID
        siteID = 0
        email = String()
        phone = nil
        stateID = 0
        status = nil
        avatarLink = String()
        displayName = (placeholderID > 0 ? f_defaultDisplayName : .jv_empty)
        title = ""
        callingDestination = -1
        callingOptions = 0
        channels = ""
        isOwner = nil
        isAdmin = false
        isSupervisor = false
        isOperator = false
        isWorking = true
        session = nil
        worktime = nil
        super.init()
    }
    
    init(json: JsonElement,
         isMe: Bool,
         ID: Int,
         siteID: Int,
         email: String,
         emailVerified: Bool?,
         phone: String?,
         stateID: Int,
         status: JVAgentStatusGeneralChange?,
         avatarLink: String,
         displayName: String,
         title: String,
         callingDestination: Int,
         callingOptions: Int,
         channels: String,
         isOwner: Bool?,
         isAdmin: Bool,
         isSupervisor: Bool,
         isOperator: Bool,
         isWorking: Bool?,
         session: JVAgentSessionGeneralChange?,
         worktime: JVAgentWorktimeGeneralChange?) {
        self.json = json
        self.isMe = isMe
        self.ID = ID
        self.siteID = siteID
        self.email = email
        self.emailVerified = emailVerified
        self.phone = phone
        self.stateID = stateID
        self.status = status
        self.avatarLink = avatarLink
        self.displayName = displayName
        self.title = title
        self.callingDestination = callingDestination
        self.callingOptions = callingOptions
        self.channels = channels
        self.isOwner = isOwner
        self.isAdmin = isAdmin
        self.isSupervisor = isSupervisor
        self.isOperator = isOperator
        self.isWorking = isWorking
        self.session = session
        self.worktime = worktime
        super.init()
    }
    
    required public convenience init(json: JsonElement) {
        self.init(json: json, isMe: false)
    }
    
    var cachable: JVAgentGeneralChange {
        return JVAgentGeneralChange(
            json: json,
            isMe: isMe,
            ID: ID,
            siteID: siteID,
            email: email,
            emailVerified: emailVerified,
            phone: phone,
            stateID: 0,
            status: nil,
            avatarLink: avatarLink,
            displayName: displayName,
            title: title,
            callingDestination: callingDestination,
            callingOptions: callingOptions,
            channels: channels,
            isOwner: isOwner,
            isAdmin: isAdmin,
            isSupervisor: isSupervisor,
            isOperator: isOperator,
            isWorking: isWorking,
            session: session,
            worktime: worktime)
    }
}

final class JVAgentShortChange: JVDatabaseModelChange {
    public let ID: Int
    public let email: String?
    public let displayName: String
    
    override var primaryValue: Int {
        return ID
    }
    
    override var isValid: Bool {
        return (ID > 0)
    }
    
    required init(json: JsonElement) {
        ID = json["agent_id"].intValue
        email = json["email"].string
        displayName = json["display_name"].stringValue
        super.init(json: json)
    }
}

final class JVAgentSdkChange: JVDatabaseModelChange {
    public let id: Int
    public let avatarLink: String?
    public let displayName: String
    public let title: String?
    
    override var primaryValue: Int {
        return id
    }
    
    override var isValid: Bool {
        return (id > 0)
    }
    
    init(
        id: Int,
        avatarLink: String? = nil,
        displayName: String,
        title: String? = nil
    ) {
        self.id = id
        self.avatarLink = avatarLink
        self.displayName = displayName
        self.title = title
        
        super.init()
    }
    
    required init(json: JsonElement) {
        abort()
    }
}

final class JVAgentLastMessageChange: JVDatabaseModelChange {
    public let ID: Int
    public let messageID: Int?
    public let messageLocalID: String?

    override var primaryValue: Int {
        return ID
    }

    var messageGlobalKey: JVDatabaseModelCustomId<Int>? {
        if let messageID = messageID {
            return JVDatabaseModelCustomId(key: "m_id", value: messageID)
        }
        else {
            return nil
        }
    }

    var messageLocalKey: JVDatabaseModelCustomId<String>? {
        if let messageLocalID = messageLocalID {
            return JVDatabaseModelCustomId(key: "m_local_id", value: messageLocalID)
        }
        else {
            return nil
        }
    }
    
    init(ID: Int, messageID: Int?, messageLocalID: String?) {
        self.ID = ID
        self.messageID = messageID
        self.messageLocalID = messageLocalID
        super.init()
    }

    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

final class JVAgentChatChange: JVDatabaseModelChange {
    public let ID: Int
    public let chatID: Int
    
    override var primaryValue: Int {
        return ID
    }
    
    init(ID: Int, chatID: Int) {
        self.ID = ID
        self.chatID = chatID
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

final class JVAgentWorktimeChange: JVDatabaseModelChange {
    public let ID: Int
    public let worktimeChange: JVAgentWorktimeBaseChange?
    
    override var primaryValue: Int {
        return ID
    }
    
    init(change: JVAgentWorktimeBaseChange) {
        ID = change.agentID
        worktimeChange = change
        super.init()
    }
    
    required init(json: JsonElement) {
        abort()
    }
}

final class JVAgentStateChange: JVDatabaseModelChange {
    public let ID: Int
    public let state: Int
    
    override var primaryValue: Int {
        return ID
    }
    
    required init(json: JsonElement) {
        if let sessionState = json.has(key: "state") {
            ID = 0
            
            switch sessionState.stringValue {
            case "online": state = JVAgentState.active.rawValue
            case "away": state = JVAgentState.away.rawValue
            default: state = JVAgentState.active.rawValue
            }
        }
        else {
            ID = json["agent_id"].intValue
            state = json["agent_state_id"].intValue
        }
        
        super.init(json: json)
    }
    
    init(ID: Int, state: Int) {
        self.ID = ID
        self.state = state
        super.init()
    }
    
    func copy(meID: Int) -> JVAgentStateChange {
        if ID > 0 {
            return self
        }
        else {
            return JVAgentStateChange(ID: meID, state: state)
        }
    }
}

final class JVAgentTypingChange: JVDatabaseModelChange {
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
        ID = json["agent_id"].intValue
        chatID = json["chat_id"].intValue

        if let typing = json["typing"].int {
            input = (typing > 0 ? json["new_val"].stringValue : nil)
        }
        else {
            input = json["new_val"].stringValue.jv_valuable
        }

        super.init(json: json)
    }

    func copy(typing: Bool) -> JVAgentTypingChange {
        return JVAgentTypingChange(ID: ID, chatID: chatID, input: input)
    }
}

final class JVAgentDraftChange: JVDatabaseModelChange {
    public let ID: Int
    public let draft: String?
    
    override var primaryValue: Int {
        return ID
    }
    
    init(ID: Int, draft: String?) {
        self.ID = ID
        self.draft = draft
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

enum AgentPropertyUpdate {
    case displayName(String)
    case title(String)
    case avatarLink(URL?)
    case status(JVAgentState)
}

class SDKAgentAtomChange: JVDatabaseModelChange {
    let id: Int
    let updates: [AgentPropertyUpdate]
    
    override var primaryValue: Int {
        abort()
    }
    
    override var integerKey: JVDatabaseModelCustomId<Int>? {
        return JVDatabaseModelCustomId<Int>(key: "m_id", value: id)
    }
    
    init(id: Int, updates: [AgentPropertyUpdate]) {
        self.id = id
        self.updates = updates
        
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

infix operator -->
func -->(node: JsonElement, option: JVAgentCallingOptions) -> Int {
    return node.intValue << option.rawValue
}
