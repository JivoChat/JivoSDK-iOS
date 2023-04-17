//
//  JVChat+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVChat {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = m_id
        }
        
        if let c = change as? JVChatGeneralChange {
            m_id = Int64(c.ID)
            
            let previousRelation = m_attendee?.relation
            
            if let lastChangeID = c.lastMessage?.ID {
                if let lastID = m_last_message?.ID, lastID != lastChangeID {
                    m_loaded_partial_history = false
                    m_loaded_entiry_history = false
                }
                else if m_last_message == nil {
                    m_loaded_partial_history = true
                }
            }
            else if !(c.isGroup == true) {
                m_loaded_partial_history = false
                m_loaded_entiry_history = false
            }
            
            if c.knownArchived {
                m_is_archived = true
                m_loaded_partial_history = false
            }
            else if !c.attendees.isEmpty {
                let attendees = context.insert(of: JVChatAttendee.self, with: c.attendees)
                e_attendees.setSet(Set(attendees.filter { $0.agent != nil }))
            }
            else {
                m_is_archived = true
            }
            
            m_client = context.upsert(of: JVClient.self, with: c.client)

            if let clientID = c.client?.ID {
                context.setValue(clientID, for: c.ID)
                
                let parsedLastMessage = c.lastMessage?.attach(clientID: clientID)
                updateLastMessageIfNeeded(context: context, change: parsedLastMessage)

                let parsedActiveRing = c.activeRing?.attach(clientID: clientID)
                m_active_ring = context.upsert(of: JVMessage.self, with: parsedActiveRing)

                m_client?.apply(
                    context: context,
                    change: JVClientHasActiveCallChange(
                        ID: clientID,
                        hasCall: c.hasActiveCall
                    )
                )
            }
            else {
                if !(c.isGroup == true && c.lastMessage == nil) {
                    updateLastMessageIfNeeded(context: context, change: c.lastMessage)
                }

                m_active_ring = context.upsert(of: JVMessage.self, with: c.activeRing)
            }
            
            let mePredicate = NSPredicate(format: "m_agent.m_session != null")
            let meAttendees = e_attendees.filtered(using: mePredicate)
            
            if let meAttendee = meAttendees.first as? JVChatAttendee {
                m_attendee = meAttendee
                e_attendees.remove(meAttendee)

                if let lastMessage = m_last_message, lastMessage.ID <= c.receivedMessageID {
                    // do-nothing
                }
                else if let unreadNumber = c.unreadNumber {
                    m_unread_number = Int16(unreadNumber)
                }
                
                m_request_cancelled_by_system = false
                m_request_cancelled_by_agent = nil
                m_transfer_cancelled = false
                m_termination_date = nil
            }
            else {
                m_attendee = m_is_archived ? nil : m_attendee
                m_unread_number = -1
            }
            
            if c.attendees.isEmpty {
                m_attendee = nil
                e_attendees.setSet(Set())
                
                m_request_cancelled_by_system = false
                m_request_cancelled_by_agent = nil
                m_termination_date = nil
            }
            
            if m_attendee?.relation != previousRelation {
                m_last_message_valid = false
                
                m_loaded_partial_history = false
                m_loaded_entiry_history = false
            }
            
            if let isGroup = c.isGroup {
                m_is_group = isGroup
            }
            
            if let isMain = c.isMain {
                m_is_main = isMain
            }
            
            if let agentID = c.agentID {
                m_owning_agent = context.agent(for: agentID, provideDefault: true)
            }
            
            m_title = c.title
            m_about = c.about ?? m_about
            m_icon = c.icon?.jv_valuable?.jv_convertToEmojis() ?? m_icon

            m_transfer_to_agent = nil
            m_transfer_to_department = nil
            m_transfer_date = nil
            m_transfer_fail_reason = nil
            
            m_last_activity_timestamp = (c.lastActivityTimestamp) ?? (m_last_message?.date.timeIntervalSince1970) ?? 0
            if let notif = notifying, !(notif == .nothing) {
                m_ordering_block = 1
            }
            else {
                m_ordering_block = 0
            }
            
            m_has_active_call = c.hasActiveCall
            m_department = c.department
        }
        else if let c = change as? JVChatShortChange {
            m_id = Int64(c.ID)
            
            if let attendee = context.insert(of: JVChatAttendee.self, with: c.attendee) {
                m_attendee = attendee
            }
            
            m_client = context.upsert(of: JVClient.self, with: c.client)
            
            m_loaded_entiry_history = false
            m_loaded_partial_history = false
            
            m_unread_number = -1
            
            m_last_activity_timestamp = Date().timeIntervalSince1970
            if let notif = notifying, !(notif == .nothing) {
                m_ordering_block = 1
            }
            else {
                m_ordering_block = 0
            }

            if let isGroup = c.isGroup {
                m_is_group = isGroup
            }
            
            m_title = c.title
            m_about = c.about ?? m_about
            m_icon = c.icon?.jv_valuable?.jv_convertToEmojis() ?? m_icon
            m_is_archived = c.isArchived
        }
        else if let c = change as? JVChatLastMessageChange {
            let wantedMessage: JVMessage?
            if let key = c.messageGlobalKey {
                let customId = JVDatabaseModelCustomId(key: key.key, value: key.value)
                wantedMessage = context.object(JVMessage.self, customId: customId)
            }
            else if let key = c.messageLocalKey {
                let customId = JVDatabaseModelCustomId(key: key.key, value: key.value)
                wantedMessage = context.object(JVMessage.self, customId: customId)
            }
            else {
                wantedMessage = nil
            }
            
            if let cm = m_last_message, let wm = wantedMessage, cm.jv_isValid, wm.date < cm.date {
                // do nothing
            }
            else if let wm = wantedMessage {
                m_last_message = wantedMessage
                m_last_activity_timestamp = max(m_last_activity_timestamp, wm.date.timeIntervalSince1970)
            }
            else {
                m_last_message = nil
            }
        }
        else if let c = change as? JVChatPreviewMessageChange {
            let wantedMessage: JVMessage?
            if let key = c.messageGlobalKey {
                let customId = JVDatabaseModelCustomId(key: key.key, value: key.value)
                wantedMessage = context.object(JVMessage.self, customId: customId)
            }
            else if let key = c.messageLocalKey {
                let customId = JVDatabaseModelCustomId(key: key.key, value: key.value)
                wantedMessage = context.object(JVMessage.self, customId: customId)
            }
            else {
                wantedMessage = nil
            }

            if let cm = m_preview_message, let wm = wantedMessage, wm.date < cm.date {
                // do nothing
            }
            else if let wm = wantedMessage {
                if wm.type == "comment" {
                    // skip, don't set
                }
                else {
                    m_preview_message = wantedMessage
                }
            }
            else {
                m_preview_message = nil
            }
        }
        else if let c = change as? JVChatHistoryChange {
            m_loaded_partial_history = c.loadedPartialHistory ?? m_loaded_partial_history
            m_loaded_entiry_history = c.loadedEntirely
            m_last_message_valid = c.lastMessageValid ?? m_last_message_valid
        }
        else if let _ = change as? JVChatResetUnreadChange {
            m_unread_number = -1
            
            m_attendee?.apply(
                context: context,
                change: JVChatAttendeeResetUnreadChange(ID: 0, messageID: lastMessage?.ID ?? 0)
            )
        }
        else if let _ = change as? JVChatIncrementUnreadChange {
            if m_unread_number >= 0 {
                m_unread_number += 1
            }
        }
        else if let c = change as? JVChatTransferRequestChange {
            m_transfer_to_agent = c.agentID.flatMap { context.agent(for: $0, provideDefault: true) }
            m_transfer_to_department = c.departmentID.flatMap { context.department(for: $0) }
            m_transfer_assisting = c.assisting
            m_transfer_date = nil
            m_transfer_comment = c.comment
            m_transfer_fail_reason = nil
        }
        else if let c = change as? JVChatTransferCompleteChange {
            m_transfer_date = c.date
            m_transfer_assisting = c.assisting
        }
        else if let c = change as? JVChatTransferRejectChange {
            if let agent = m_transfer_to_agent {
                switch c.reason {
                case .rejectByAgent:
                    let name = agent.displayName(kind: .original)
                    m_transfer_fail_reason = c.assisting
                        ? loc[format: "Chat.System.Assist.Failed.RejectByAgent", name]
                        : loc[format: "Chat.System.Transfer.Failed.RejectByAgent", name]

                case .rejectByDepartment, .unknown:
                    m_transfer_fail_reason = c.assisting
                        ? loc["Chat.System.Assist.Failed.Unknown"]
                        : loc["Chat.System.Transfer.Failed.Unknown"]
                }
            }
            else if let department = m_transfer_to_department {
                switch c.reason {
                case .rejectByDepartment:
                    let name = department.displayName(kind: .original)
                    m_transfer_fail_reason = loc[format: "Chat.System.Transfer.Failed.RejectByDepartment", name]

                case .rejectByAgent, .unknown:
                    m_transfer_fail_reason = loc["Chat.System.Transfer.Failed.Unknown"]
                }
            }
            else {
                m_transfer_to_agent = nil
                m_transfer_to_department = nil
                m_transfer_date = nil
                m_transfer_fail_reason = nil
            }
        }
        else if change is JVChatTransferCancelChange {
            m_transfer_to_agent = nil
            m_transfer_to_department = nil
            m_transfer_date = nil
            m_transfer_fail_reason = nil
        }
        else if change is JVChatFinishedChange {
            m_unread_number = -1
            m_request_cancelled_by_system = true
            m_request_cancelled_by_agent = nil
            m_transfer_cancelled = false
        }
        else if let c = change as? JVChatRequestCancelledChange {
            let agent = context.agent(for: c.acceptedByID, provideDefault: true)
            
            m_unread_number = -1
            m_request_cancelled_by_system = false
            m_request_cancelled_by_agent = agent
            m_transfer_cancelled = true
        }
        else if let _ = change as? JVChatRequestCancelChange {
            m_unread_number = -1
            m_transfer_cancelled = true
        }
        else if let _ = change as? JVChatAcceptChange {
            m_attendee?.apply(context: context, change: JVChatAttendeeAcceptChange())
        }
        else if change is JVChatAcceptFailChange {
            assertionFailure()
        }
        else if let c = change as? JVChatTerminationChange {
            m_transfer_date = c.date
        }
        else if let c = change as? JVChatDraftChange {
            m_draft = c.draft
        }
        else if let c = change as? JVSdkChatAgentsUpdateChange {
            let agents = c.agentIds.map { context.agent(for: $0, provideDefault: true) }
            
            if c.exclusive {
                e_agents.setSet(Set(agents))
            }
            else {
                e_agents.union(Set(agents))
            }
        }
        else {
            assertionFailure()
        }
    }
    
    private var e_attendees: NSMutableSet {
        return mutableSetValue(forKeyPath: #keyPath(JVChat.m_attendees))
    }
    
    private var e_agents: NSMutableSet {
        return mutableSetValue(forKeyPath: #keyPath(JVChat.m_agents))
    }
    
    private func updateLastMessageIfNeeded(context: JVIDatabaseContext, change: JVMessageLocalChange?) {
        guard let message = m_last_message else {
            m_last_message = context.upsert(of: JVMessage.self, with: change)
            m_last_activity_timestamp = max(m_last_activity_timestamp, TimeInterval(change?.creationTS ?? 0))
            return
        }

        guard let change = change else {
            m_last_message = nil
            return
        }

        let hasLaterID = (change.ID > message.ID)
        let hasLaterTime = (TimeInterval(change.creationTS) >= message.date.timeIntervalSince1970)

        guard hasLaterID || hasLaterTime else {
            return
        }

        if let _ = context.messageWithCallID(change.body?.callID) {
            m_last_message = context.update(of: JVMessage.self, with: change.copy(ID: message.ID))
            m_last_activity_timestamp = max(m_last_activity_timestamp, TimeInterval(change.creationTS))
        }
        else {
            m_last_message = context.upsert(of: JVMessage.self, with: change)
            m_last_activity_timestamp = max(m_last_activity_timestamp, TimeInterval(change.creationTS))
        }
    }
}

public final class JVChatGeneralChange: JVDatabaseModelChange {
    public let ID: Int
    public let attendees: [JVChatAttendeeGeneralChange]
    public let client: JVClientShortChange?
    public let agentID: Int?
    public let lastMessage: JVMessageLocalChange?
    public let activeRing: JVMessageLocalChange?
    public let relation: String?
    public let isGroup: Bool?
    public let isMain: Bool?
    public let title: String?
    public let about: String?
    public let icon: String?
    public let receivedMessageID: Int
    public let unreadNumber: Int?
    public let lastActivityTimestamp: TimeInterval?
    public let hasActiveCall: Bool
    public let department: String?
    public let knownArchived: Bool

    public override var primaryValue: Int {
        return ID
    }
    
    public override var isValid: Bool {
        guard ID > 0 else { return false }
        return true
    }
    
    public init(ID: Int,
         attendees: [JVChatAttendeeGeneralChange],
         client: JVClientShortChange?,
         agentID: Int?,
         lastMessage: JVMessageLocalChange?,
         activeRing: JVMessageLocalChange?,
         relation: String?,
         isGroup: Bool?,
         isMain: Bool?,
         title: String?,
         about: String?,
         icon: String?,
         receivedMessageID: Int,
         unreadNumber: Int?,
         lastActivityTimestamp: TimeInterval?,
         hasActiveCall: Bool,
         department: String?,
         knownArchived: Bool) {
        self.ID = ID
        self.attendees = attendees
        self.client = client
        self.agentID = agentID
        self.lastMessage = lastMessage
        self.activeRing = activeRing
        self.relation = relation
        self.isGroup = isGroup
        self.isMain = isMain
        self.title = title
        self.about = about
        self.icon = icon
        self.receivedMessageID = receivedMessageID
        self.unreadNumber = unreadNumber
        self.lastActivityTimestamp = lastActivityTimestamp
        self.hasActiveCall = hasActiveCall
        self.department = department
        self.knownArchived = knownArchived
        super.init()
    }
    
    required public init(json: JsonElement) {
        let parsedLastMessage: JVMessageLocalChange? = json["last_message"].parse()
        let parsedActiveRing: JVMessageLocalChange? = json["active_ring"].parse()
        
        ID = json["chat_id"].intValue
        client = json["client"].parse()
        agentID = json["agent_id"].int
        relation = nil
        isGroup = json["is_group"].bool
        isMain = json["is_main"].bool
        title = json["title"].string
        about = json["description"].string?.jv_valuable
        icon = json["icon"].string
        receivedMessageID = 0
        unreadNumber = json["count_unread"].int
        
        if let _ = client {
            attendees = json["attendees"].parseList() ?? []
        }
        else {
            let values: [JVChatAttendeeGeneralChange] = json["attendees"].parseList() ?? []
            attendees = values.map { $0.copy(relation: "") }
        }
        
        if let clientID = client?.ID {
            lastMessage = parsedLastMessage?.attach(clientID: clientID)
            activeRing = parsedActiveRing?.attach(clientID: clientID)
        }
        else {
            lastMessage = parsedLastMessage
            activeRing = parsedActiveRing
        }

        lastActivityTimestamp = json["latest_activity_date"].double
        hasActiveCall = (json.has(key: "active_call") != nil)
        department = json["department"]["display_name"].string
        knownArchived = false

        super.init(json: json)
    }
    
    /*
    public func copy(without me: _JVAgent) -> JVChatGeneralChange {
        if let meAttendee = attendees.first(where: { $0.ID == me.ID }) ?? attendees.first {
            return JVChatGeneralChange(
                ID: ID,
                attendees: attendees.filter({ $0 !== meAttendee }),
                client: client,
                agentID: agentID,
                lastMessage: lastMessage,
                activeRing: activeRing,
                relation: meAttendee.relation,
                isGroup: isGroup,
                isMain: isMain,
                title: title,
                about: about,
                icon: icon,
                receivedMessageID: receivedMessageID,
                unreadNumber: unreadNumber,
                lastActivityTimestamp: lastActivityTimestamp,
                hasActiveCall: hasActiveCall,
                department: department,
                knownArchived: knownArchived)
        }
        else {
            return self
        }
    }
    */

    public func copy(without meId: Int) -> JVChatGeneralChange {
        if let meAttendee = attendees.first(where: { $0.ID == meId }) ?? attendees.first {
            return JVChatGeneralChange(
                ID: ID,
                attendees: attendees.filter({ $0 !== meAttendee }),
                client: client,
                agentID: agentID,
                lastMessage: lastMessage,
                activeRing: activeRing,
                relation: meAttendee.relation,
                isGroup: isGroup,
                isMain: isMain,
                title: title,
                about: about,
                icon: icon,
                receivedMessageID: receivedMessageID,
                unreadNumber: unreadNumber,
                lastActivityTimestamp: lastActivityTimestamp,
                hasActiveCall: hasActiveCall,
                department: department,
                knownArchived: knownArchived)
        }
        else {
            return self
        }
    }

    public func copy(relation: String, everybody: Bool) -> JVChatGeneralChange {
        guard attendees.count == 1 || everybody else { return self }

        return JVChatGeneralChange(
            ID: ID,
            attendees: attendees.map { $0.copy(relation: relation) },
            client: client,
            agentID: agentID,
            lastMessage: lastMessage,
            activeRing: activeRing,
            relation: relation,
            isGroup: isGroup,
            isMain: isMain,
            title: title,
            about: about,
            icon: icon,
            receivedMessageID: receivedMessageID,
            unreadNumber: unreadNumber,
            lastActivityTimestamp: lastActivityTimestamp,
            hasActiveCall: hasActiveCall,
            department: department,
            knownArchived: knownArchived)
    }
    
    public func copy(receivedMessageID: Int? = nil, knownArchived: Bool? = nil) -> JVChatGeneralChange {
        return JVChatGeneralChange(
            ID: ID,
            attendees: attendees,
            client: client,
            agentID: agentID,
            lastMessage: lastMessage,
            activeRing: activeRing,
            relation: relation,
            isGroup: isGroup,
            isMain: isMain,
            title: title,
            about: about,
            icon: icon,
            receivedMessageID: receivedMessageID ?? self.receivedMessageID,
            unreadNumber: unreadNumber,
            lastActivityTimestamp: lastActivityTimestamp,
            hasActiveCall: hasActiveCall,
            department: department,
            knownArchived: knownArchived ?? self.knownArchived)
    }
    
    public func cachable() -> JVChatGeneralChange {
        return JVChatGeneralChange(
            ID: ID,
            attendees: attendees.map { $0.cachable() },
            client: client,
            agentID: agentID,
            lastMessage: lastMessage,
            activeRing: activeRing,
            relation: relation,
            isGroup: isGroup,
            isMain: isMain,
            title: title,
            about: about,
            icon: icon,
            receivedMessageID: receivedMessageID,
            unreadNumber: 0,
            lastActivityTimestamp: lastActivityTimestamp,
            hasActiveCall: hasActiveCall,
            department: department,
            knownArchived: knownArchived)
    }
    
    public func findAttendeeRelation(agentID: Int) -> String? {
        for attendee in attendees {
            guard attendee.ID == agentID else { continue }
            return attendee.relation
        }
        
        return nil
    }
}

public final class JVChatShortChange: JVDatabaseModelChange, NSCoding {
    public let ID: Int
    public let client: JVClientShortChange?
    public let attendee: JVChatAttendeeGeneralChange?
    public let relation: String?
    public let teammateID: Int?
    public let isGroup: Bool?
    public let title: String?
    public let about: String?
    public let icon: String?
    public let isArchived: Bool
    
    private let codableIdKey = "id"
    private let codableClientKey = "client"
    private let codableAttendeeKey = "attendee"
    private let codableRelationKey = "relation"
    private let codableTeammateKey = "teammate"
    private let codableGroupKey = "group"
    private let codableTitleKey = "title"
    private let codableAboutKey = "about"
    private let codableIconKey = "icon"
    private let codableArchivedKey = "is_archived"
    
    public override var primaryValue: Int {
        return ID
    }
    
    public convenience init(ID: Int, clientID: Int) {
        self.init(
            ID: ID,
            client: JVClientShortChange(
                ID: clientID,
                channelID: nil,
                task: nil),
            attendee: nil,
            teammateID: nil,
            isGroup: nil,
            title: nil,
            about: nil,
            icon: nil,
            isArchived: true)
    }
    
    public init(
        ID: Int,
        client: JVClientShortChange?,
        attendee: JVChatAttendeeGeneralChange?,
        teammateID: Int?,
        isGroup: Bool?,
        title: String?,
        about: String?,
        icon: String?,
        isArchived: Bool
    ) {
        self.ID = ID
        self.client = client
        self.attendee = attendee
        self.teammateID = teammateID
        self.relation = attendee?.relation
        self.isGroup = isGroup
        self.title = title
        self.about = about
        self.icon = icon
        self.isArchived = isArchived
        super.init()
    }
    
    required public init(json: JsonElement) {
        ID = json["chat_id"].intValue
        client = json["client"].parse()
        attendee = nil
        relation = json["rel"].string ?? "invited"
        teammateID = nil
        isGroup = json["is_group"].bool
        title = json["title"].string
        about = json["about"].string
        icon = json["icon"].string
        isArchived = false
        super.init(json: json)
    }
    
    public init?(coder: NSCoder) {
        ID = coder.decodeInteger(forKey: codableIdKey)
        client = coder.decodeObject(of: JVClientShortChange.self, forKey: codableClientKey)
        attendee = coder.decodeObject(of: JVChatAttendeeGeneralChange.self, forKey: codableAttendeeKey)
        relation = coder.decodeObject(forKey: codableRelationKey) as? String
        teammateID = coder.decodeObject(forKey: codableTeammateKey) as? Int
        isGroup = coder.decodeObject(of: NSNumber.self, forKey: codableGroupKey)?.boolValue
        title = coder.decodeObject(forKey: codableTitleKey) as? String
        about = coder.decodeObject(forKey: codableAboutKey) as? String
        icon = coder.decodeObject(forKey: codableIconKey) as? String
        isArchived = coder.decodeBool(forKey: codableArchivedKey)
        super.init()
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(ID, forKey: codableIdKey)
        coder.encode(client, forKey: codableClientKey)
        coder.encode(attendee, forKey: codableAttendeeKey)
        coder.encode(relation, forKey: codableRelationKey)
        coder.encode(teammateID, forKey: codableTeammateKey)
        coder.encode(isGroup.flatMap(NSNumber.init), forKey: codableGroupKey)
        coder.encode(title, forKey: codableTitleKey)
        coder.encode(about, forKey: codableAboutKey)
        coder.encode(icon, forKey: codableIconKey)
        coder.encode(isArchived, forKey: codableArchivedKey)
    }
    
    public func copy(attendeeID: Int,
              rel: String?,
              comment: String?,
              invitedBy: Int?,
              isAssistant: Bool) -> JVChatShortChange {
        return JVChatShortChange(
            ID: ID,
            client: client,
            attendee: JVChatAttendeeGeneralChange(
                ID: attendeeID,
                relation: rel ?? relation,
                comment: comment,
                invitedBy: invitedBy,
                isAssistant: isAssistant,
                receivedMessageID: 0,
                unreadNumber: 0,
                notifications: nil
            ),
            teammateID: teammateID,
            isGroup: isGroup,
            title: title,
            about: about,
            icon: icon,
            isArchived: isArchived
        )
    }
}

public final class JVChatLastMessageChange: JVDatabaseModelChange {
    public let chatID: Int
    public let messageID: Int?
    public let messageLocalID: String?
    
    public override var primaryValue: Int {
        return chatID
    }
    
    public var messageGlobalKey: JVDatabaseModelCustomId<Int>? {
        if let messageID = messageID {
            return JVDatabaseModelCustomId(key: "m_id", value: messageID)
        }
        else {
            return nil
        }
    }
    
    public var messageLocalKey: JVDatabaseModelCustomId<String>? {
        if let messageLocalID = messageLocalID {
            return JVDatabaseModelCustomId(key: "m_local_id", value: messageLocalID)
        }
        else {
            return nil
        }
    }
    
    public init(chatID: Int, messageID: Int?, messageLocalID: String?) {
        self.chatID = chatID
        self.messageID = messageID
        self.messageLocalID = messageLocalID
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVChatPreviewMessageChange: JVDatabaseModelChange {
    public let chatID: Int
    public let messageID: Int?
    public let messageLocalID: String?

    public override var primaryValue: Int {
        return chatID
    }

    public var messageGlobalKey: JVDatabaseModelCustomId<Int>? {
        if let messageID = messageID {
            return JVDatabaseModelCustomId(key: "m_id", value: messageID)
        }
        else {
            return nil
        }
    }

    public var messageLocalKey: JVDatabaseModelCustomId<String>? {
        if let messageLocalID = messageLocalID {
            return JVDatabaseModelCustomId(key: "m_local_id", value: messageLocalID)
        }
        else {
            return nil
        }
    }
    
    public init(chatID: Int, messageID: Int?, messageLocalID: String?) {
        self.chatID = chatID
        self.messageID = messageID
        self.messageLocalID = messageLocalID
        super.init()
    }

    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVChatHistoryChange: JVDatabaseModelChange {
    public let loadedPartialHistory: Bool?
    public let loadedEntirely: Bool
    public let lastMessageValid: Bool?
    
    public init(loadedPartialHistory: Bool?, loadedEntirely: Bool, lastMessageValid: Bool?) {
        self.loadedPartialHistory = loadedPartialHistory
        self.loadedEntirely = loadedEntirely
        self.lastMessageValid = lastMessageValid
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVChatIncrementUnreadChange: JVDatabaseModelChange {
    public let ID: Int
    
    public override var primaryValue: Int {
        return ID
    }
    
    public init(ID: Int) {
        self.ID = ID
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVChatResetUnreadChange: JVDatabaseModelChange {
    public let ID: Int
    
    public override var primaryValue: Int {
        return ID
    }
    
    public init(ID: Int) {
        self.ID = ID
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVChatTransferRequestChange: JVDatabaseModelChange {
    public let ID: Int
    public let agentID: Int?
    public let departmentID: Int?
    public let assisting: Bool
    public let comment: String?
    
    public override var primaryValue: Int {
        return ID
    }
    
    public init(ID: Int, agentID: Int?, departmentID: Int?, assisting: Bool, comment: String?) {
        self.ID = ID
        self.agentID = agentID
        self.departmentID = departmentID
        self.assisting = assisting
        self.comment = comment
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVChatTransferCompleteChange: JVDatabaseModelChange {
    public let ID: Int
    public let date: Date
    public let assisting: Bool
    
    public override var primaryValue: Int {
        return ID
    }
    
    required public init(json: JsonElement) {
        ID = json["chat_id"].intValue
        date = Date()
        assisting = json["assistant"].boolValue
        super.init(json: json)
    }
}

public final class JVChatTransferRejectChange: JVDatabaseModelChange {
    public enum Reason: String {
        case rejectByAgent = "target_agent_reject"
        case rejectByDepartment = "target_group_reject"
        case unknown
    }
    
    public let ID: Int
    public let assisting: Bool
    public let reason: Reason
    
    public override var primaryValue: Int {
        return ID
    }
    
    required public init(json: JsonElement) {
        ID = json["chat_id"].intValue
        assisting = json["assistant"].boolValue
        reason = Reason(rawValue: json["reason"].stringValue) ?? .unknown
        super.init(json: json)
    }
}

public final class JVChatTransferCancelChange: JVDatabaseModelChange {
    public let ID: Int
    
    public override var primaryValue: Int {
        return ID
    }
    
    public init(ID: Int) {
        self.ID = ID
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVChatFinishedChange: JVDatabaseModelChange {
    public let ID: Int
    
    public override var primaryValue: Int {
        return ID
    }
    
    required public init(json: JsonElement) {
        self.ID = json["chat_id"].intValue
        super.init(json: json)
    }
    
    public init(ID: Int) {
        self.ID = ID
        super.init()
    }
}

public final class JVChatRequestCancelledChange: JVDatabaseModelChange {
    public let ID: Int
    public let acceptedByID: Int
    
    public override var primaryValue: Int {
        return ID
    }
    
    public init(ID: Int, acceptedByID: Int) {
        self.ID = ID
        self.acceptedByID = acceptedByID
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVChatRequestCancelChange: JVDatabaseModelChange {
    public let ID: Int
    
    public override var primaryValue: Int {
        return ID
    }
    
    public init(ID: Int) {
        self.ID = ID
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVChatAcceptChange: JVDatabaseModelChange {
    public let ID: Int
    public let clientID: Int
    
    public override var primaryValue: Int {
        return ID
    }
    
    required public init(json: JsonElement) {
        ID = json["chat_id"].intValue
        clientID = json["client_id"].intValue
        super.init(json: json)
    }
}

public final class JVChatAcceptFailChange: JVDatabaseModelChange {
    public enum Reason: String {
        case alreadyAccepted = "client_already_has_agent_id"
        case hasCall = "chat_has_cw_call"
        case unknown
    }
    
    public let ID: Int
    public let clientID: Int
    public let acceptedAgentID: Int?
    public let reason: Reason
    
    public override var primaryValue: Int {
        return ID
    }
    
    required public init(json: JsonElement) {
        ID = json["chat_id"].intValue
        clientID = json["client_id"].intValue
        acceptedAgentID = json["accepted_agent_id"].intValue.jv_valuable
        reason = Reason(rawValue: json["reason"].stringValue) ?? .unknown
        super.init(json: json)
    }
}

public final class JVChatTerminationChange: JVDatabaseModelChange {
    public let ID: Int
    public let date: Date
    
    public override var primaryValue: Int {
        return ID
    }
    
    public init(ID: Int, delay: TimeInterval) {
        self.ID = ID
        self.date = Date().addingTimeInterval(delay)
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVChatDraftChange: JVDatabaseModelChange {
    public let ID: Int
    public let draft: String?
    
    public override var primaryValue: Int {
        return ID
    }
    
    public init(ID: Int, draft: String?) {
        self.ID = ID
        self.draft = draft
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVSdkChatAgentsUpdateChange: JVDatabaseModelChange {
    public let id: Int
    public let agentIds: [Int]
    public let exclusive: Bool
    
    public override var primaryValue: Int {
        return id
    }
    
    public init(id: Int, agentIds: [Int], exclusive: Bool) {
        self.id = id
        self.agentIds = agentIds
        self.exclusive = exclusive
        
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

