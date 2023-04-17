//
//  JVChatAttendee+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVChatAttendee {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let c = change as? JVChatAttendeeGeneralChange {
            m_agent = context.agent(for: c.ID, provideDefault: true)
            m_relation = c.relation
            m_comment = c.comment
            m_invited_by = c.invitedBy.flatMap { $0 > 0 ? context.agent(for: $0, provideDefault: true) : nil }
            m_to_assist = c.isAssistant
            m_received_message_id = Int64(c.receivedMessageID ?? 0)
            m_unread_number = Int16(c.unreadNumber ?? 0)
            m_notifications = c.notifications?.jv_toInt16 ?? m_notifications
        }
        else if let _ = change as? JVChatAttendeeAcceptChange {
            m_relation = "attendee"
        }
        else if let c = change as? JVChatAttendeeNotificationsChange {
            m_notifications = Int16(c.notifications)
        }
        else if let c = change as? JVChatAttendeeResetUnreadChange {
            m_received_message_id = Int64(c.messageID)
            m_unread_number = 0
        }
    }
}

public final class JVChatAttendeeGeneralChange: JVDatabaseModelChange, NSCoding {
    public let ID: Int
    public let relation: String?
    public let comment: String?
    public let invitedBy: Int?
    public let isAssistant: Bool
    public let receivedMessageID: Int?
    public let unreadNumber: Int?
    public let notifications: Int?
    
    private let codableIdKey = "id"
    private let codableRelationKey = "relation"
    private let codableCommentKey = "comment"
    private let codableInviterKey = "inviter"
    private let codableAssistingKey = "assisting"
    private let codableReceivedKey = "received"
    private let codableUnreadKey = "unread"
    private let codableNotificationsKey = "notifications"
    
    public init(ID: Int,
         relation: String?,
         comment: String?,
         invitedBy: Int?,
         isAssistant: Bool,
         receivedMessageID: Int?,
         unreadNumber: Int?,
         notifications: Int?) {
        self.ID = ID
        self.relation = relation
        self.comment = comment
        self.invitedBy = invitedBy
        self.isAssistant = isAssistant
        self.receivedMessageID = receivedMessageID
        self.unreadNumber = unreadNumber
        self.notifications = notifications
        super.init()
    }
    
    required public init(json: JsonElement) {
        ID = json["agent_id"].intValue
        relation = json["rel"].valuable
        comment = json["comment"].valuable
        invitedBy = (json["by"].intValue > 0 ? json["by"].int : nil)
        isAssistant = json["assistant"].boolValue
        receivedMessageID = json["received_msg_id"].int
        unreadNumber = json["unread_number"].int
        notifications = json["notifications"].int
        super.init(json: json)
    }
    
    public init?(coder: NSCoder) {
        ID = coder.decodeInteger(forKey: codableIdKey)
        relation = coder.decodeObject(forKey: codableRelationKey) as? String
        comment = coder.decodeObject(forKey: codableCommentKey) as? String
        invitedBy = coder.decodeObject(forKey: codableInviterKey) as? Int
        isAssistant = coder.decodeBool(forKey: codableAssistingKey)
        receivedMessageID = coder.decodeObject(forKey: codableReceivedKey) as? Int
        unreadNumber = coder.decodeObject(forKey: codableUnreadKey) as? Int
        notifications = coder.decodeObject(forKey: codableNotificationsKey) as? Int
        super.init()
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(ID, forKey: codableIdKey)
        coder.encode(relation, forKey: codableRelationKey)
        coder.encode(comment, forKey: codableCommentKey)
        coder.encode(invitedBy, forKey: codableInviterKey)
        coder.encode(isAssistant, forKey: codableAssistingKey)
        coder.encode(receivedMessageID, forKey: codableReceivedKey)
        coder.encode(unreadNumber, forKey: codableUnreadKey)
        coder.encode(notifications, forKey: codableNotificationsKey)
    }
    
    public func copy(relation: String) -> JVChatAttendeeGeneralChange {
        return JVChatAttendeeGeneralChange(
            ID: ID,
            relation: relation,
            comment: comment,
            invitedBy: invitedBy,
            isAssistant: isAssistant,
            receivedMessageID: receivedMessageID,
            unreadNumber: unreadNumber,
            notifications: notifications
        )
    }
    
    public func cachable() -> JVChatAttendeeGeneralChange {
        return JVChatAttendeeGeneralChange(
            ID: ID,
            relation: relation,
            comment: comment,
            invitedBy: invitedBy,
            isAssistant: isAssistant,
            receivedMessageID: 0,
            unreadNumber: 0,
            notifications: notifications
        )
    }
}

public final class JVChatAttendeeAcceptChange: JVDatabaseModelChange {
}

public final class JVChatAttendeeResetUnreadChange: JVDatabaseModelChange {
    public let ID: Int
    public let messageID: Int
    
    public init(ID: Int, messageID: Int) {
        self.ID = ID
        self.messageID = messageID
        super.init()
    }
    
    required public init(json: JsonElement) {
        abort()
    }
}

public final class JVChatAttendeeNotificationsChange: JVDatabaseModelChange {
    public let ID: Int
    public let notifications: Int
    
    public init(ID: Int, notifications: Int) {
        self.ID = ID
        self.notifications = notifications
        super.init()
    }
    
    required public init(json: JsonElement) {
        abort()
    }
}

