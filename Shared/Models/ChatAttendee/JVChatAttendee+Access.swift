//
//  JVChatAttendee+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

public enum JVChatAttendeeNotifying: Int {
    case nothing = 0
    case everything = 1
    case mentions = 2
    
    public static var allCases: [JVChatAttendeeNotifying] {
        return [.everything, .nothing, .mentions]
    }
}

public enum JVChatAttendeeRelation: Equatable {
    case invitedBySystem
    case invitedByAgent(JVAgent, toAssist: Bool, comment: String?)
    case attendee(agent: JVAgent?, toAssist: Bool, comment: String?)
    case team
    
    public var code: String {
        switch self {
        case .invitedBySystem:
            return "invited"
        case .invitedByAgent:
            return "invited"
        case .attendee:
            return "attendee"
        case .team:
            return String()
        }
    }
    
    public var isInvited: Bool {
        switch self {
        case .invitedBySystem:
            return true
        case .invitedByAgent:
            return true
        case .attendee:
            return false
        case .team:
            return false
        }
    }
}

public extension JVChatAttendee {
    var agent: JVAgent? {
        return m_agent
    }
    
    var relation: JVChatAttendeeRelation {
        if m_relation == "invited" {
            if let agent = invitedBy {
                return .invitedByAgent(agent, toAssist: m_to_assist, comment: m_comment)
            }
            else {
                return .invitedBySystem
            }
        }
        else if m_relation == "attendee" {
            return .attendee(agent: m_invited_by, toAssist: m_to_assist, comment: m_comment)
        }
        else {
            return .team
        }
    }
    
    var comment: String? {
        return m_comment
    }
    
    var invitedBy: JVAgent? {
        return m_invited_by
    }
    
    var isAssistant: Bool {
        return m_to_assist
    }
    
    var receivedMessageID: Int? {
        if m_received_message_id > 0 {
            return Int(m_received_message_id)
        }
        else {
            return nil
        }
    }
    
    var unreadNumber: Int? {
        if m_unread_number > 0 {
            return Int(m_unread_number)
        }
        else {
            return nil
        }
    }
    
    var notifying: JVChatAttendeeNotifying? {
        return JVChatAttendeeNotifying(rawValue: Int(m_notifications))
    }
    
    func export() -> JVChatAttendeeGeneralChange {
        return JVChatAttendeeGeneralChange(
            ID: m_agent?.ID ?? 0,
            relation: m_relation,
            comment: m_comment,
            invitedBy: m_invited_by?.ID,
            isAssistant: m_to_assist,
            receivedMessageID: Int(m_received_message_id),
            unreadNumber: Int(m_unread_number),
            notifications: Int(m_notifications)
        )
    }
}

public func ==(lhs: JVChatAttendeeRelation, rhs: JVChatAttendeeRelation) -> Bool {
    if case .invitedBySystem = lhs, case .invitedBySystem = rhs {
        return true
    }
    else if case let .invitedByAgent(f1, f2, f3) = lhs, case let .invitedByAgent(s1, s2, s3) = rhs {
        return (f1 == s1 && f2 == s2 && f3 == s3)
    }
    else if case .attendee = lhs, case .attendee = rhs {
        return true
    }
    else if case .team = lhs, case .team = rhs {
        return true
    }
    else {
        return false
    }
}
