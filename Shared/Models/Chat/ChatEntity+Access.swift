//
//  ChatEntity+Access.swift
//  App
//
//  Created by Stan Potemkin on 16.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMRepicKit

enum RosterBox: String {
    case inbox
    case my
    case team
    case groups
    case archive
}

enum JVChatInvitationState {
    case none
    case activeBySystem
    case activeByAgent(AgentEntity)
    case cancelBySystem
    case cancelByAgent(AgentEntity)
    
    var isNone: Bool {
        if case .none = self {
            return true
        }
        else {
            return false
        }
    }
}

enum JVChatReactionPerforming {
    case accept
    case decline
    case spam
    case close
}

enum JVChatAttendeeAssignment {
    case assignedWithMe
    case assignedToAnother
    case notPresented
}

enum JVChatTransferState {
    case none
    case requested(agent: AgentEntity, assisting: Bool, comment: String?)
    case completed(agent: AgentEntity, assisting: Bool, date: Date, comment: String?)
    case rejected(agent: AgentEntity, assisting: Bool, reason: String)
    case requestedDepartment(department: DepartmentEntity, comment: String?)
    case completedDepartment(department: DepartmentEntity, date: Date, comment: String?)
    case rejectedDepartment(department: DepartmentEntity, reason: String)
}

extension ChatEntity: JVPresentable {
    func repicItem(transparent: Bool, scale: CGFloat?) -> JMRepicItem? {
        guard isGroup else { return nil }
        guard let code = m_icon?.jv_valuable else { return nil }
        
        return JMRepicItem(
            backgroundColor: JVDesign.colors.resolve(usage: .contentBackground),
            source: JMRepicItemSource.caption(code, JVDesign.fonts.emoji(scale: scale)),
            scale: scale ?? 0.55,
            clipping: .external
        )
    }
    
    var ID: Int {
        return Int(m_id)
    }
    
    var isGroup: Bool {
        return m_is_group
    }
    
    var isMain: Bool {
        return m_is_main
    }
    
    var client: ClientEntity? {
        return m_client
    }
    
    var hasClient: Bool {
        return (client != nil)
    }
    
    var title: String {
        return m_title ?? client?.displayName(kind: .decorative(.role)) ?? String()
    }
    
    var about: String? {
        return m_about?.jv_valuable
    }
    
    var topic: TopicEntity? {
        return m_topic
    }
    
    var attendees: [ChatAttendeeEntity] {
        if let allObjects = m_attendees?.allObjects as? [ChatAttendeeEntity] {
            return allObjects
        }
        else {
            return Array()
        }
    }
    
    var attendee: ChatAttendeeEntity? {
        return m_attendee
    }
    
    var allAttendees: [ChatAttendeeEntity] {
        return attendees.filter {
            if case .attendee = $0.relation {
                return true
            }
            else {
                return false
            }
        }
    }
    
    var isIncomingAppeal: Bool {
        guard let relation = attendee?.relation else {
            return false
        }
        
        if case .invitedBySystem = relation {
            return true
        }
        else {
            return false
        }
    }
    
    var invitationState: JVChatInvitationState {
        if m_request_cancelled_by_system {
            return .cancelBySystem
        }
        else if let agent = m_request_cancelled_by_agent {
            return .cancelByAgent(agent)
        }
        else if let attendee = attendee {
            if case .invitedBySystem = attendee.relation {
                return m_transfer_cancelled ? .none : .activeBySystem
            }
            else if case .invitedByAgent(let agent, _, _) = attendee.relation {
                return m_transfer_cancelled ? .none : .activeByAgent(agent)
            }
            else {
                return .none
            }
        }
        else {
            return .none
        }
    }
    
    var isCancelled: Bool {
        switch invitationState {
        case .none:
            return false
        case .activeBySystem:
            return false
        case .activeByAgent:
            return false
        case .cancelBySystem:
            return true
        case .cancelByAgent:
            return true
        }
    }
    
    var isResolved: Bool {
        return m_is_resolved
    }
    
    var agents: [AgentEntity] {
        return attendees.compactMap { $0.agent }
    }
    
    var lastMessage: MessageEntity? {
        return m_last_message
    }
    
    var previewMessage: MessageEntity? {
        return m_preview_message ?? m_last_message
    }

    var lastMessageValid: Bool {
        return m_last_message_valid
    }
    
    var loadedPartialHistory: Bool {
        return m_loaded_partial_history
    }
    
    var loadedEntireHistory: Bool {
        return m_loaded_entiry_history
    }
    
    var realUnreadNumber: Int {
        if let message = m_last_message, message.sentByMe {
            return 0
        }
        else if m_unread_number > -1 {
            return Int(m_unread_number)
        }
        else if let identifier = attendee?.receivedMessageID, let lastID = lastMessage?.ID {
            return (identifier == lastID ? 0 : 1)
        }
        else {
            return 0
        }
    }
    
    var notifyingUnreadNumber: Int {
        if notifying == .nothing {
            return 0
        }
        else {
            return realUnreadNumber
        }
    }
    
    enum UnreadMarkPosition { case null, position(Int), identifier(Int) }
    var unreadMarkPosition: UnreadMarkPosition {
        if let message = lastMessage, message.sentByMe {
            return .null
        }
        else if let identifier = attendee?.receivedMessageID, let lastID = lastMessage?.ID {
            return (identifier == lastID ? .null : .identifier(identifier))
        }
        else {
            return (realUnreadNumber > 0 ? .position(realUnreadNumber) : .null)
        }
    }
    
    var transferState: JVChatTransferState {
        if let agent = m_transfer_to_agent {
            if let date = m_transfer_date {
                return .completed(
                    agent: agent,
                    assisting: m_transfer_assisting,
                    date: date,
                    comment: m_transfer_comment
                )
            }
            else if let reason = m_transfer_fail_reason {
                return .rejected(
                    agent: agent,
                    assisting: m_transfer_assisting,
                    reason: reason
                )
            }
            else {
                return .requested(
                    agent: agent,
                    assisting: m_transfer_assisting,
                    comment: m_transfer_comment
                )
            }
        }
        else if let department = m_transfer_to_department {
            if let date = m_transfer_date {
                return .completedDepartment(
                    department: department,
                    date: date,
                    comment: m_transfer_comment
                )
            }
            else if let reason = m_transfer_fail_reason {
                return .rejectedDepartment(
                    department: department,
                    reason: reason
                )
            }
            else {
                return .requestedDepartment(
                    department: department,
                    comment: m_transfer_comment
                )
            }
        }
        else {
            return .none
        }
    }
    
    var terminationDate: Date? {
        return m_termination_date
    }

    var hasActiveCall: Bool {
        return m_has_active_call
    }
    
    var lastActivityTimestamp: TimeInterval {
        return m_last_activity_timestamp
    }
    
    var department: String? {
        return m_department?.jv_valuable
    }
    
    var draft: String? {
        return m_draft?.jv_valuable
    }
    
    var notifying: JVChatAttendeeNotifying? {
        if isGroup {
            return attendee?.notifying
        }
        else {
            return .everything
        }
    }
    
    var senderType: JVSenderType {
        return .teamchat
    }
    
    var supportsQuoting: Bool {
        switch attendee?.relation {
        case .attendee:
            return true
        case .team:
            return true
        default:
            return false
        }
    }
    
    func doesRelateTo(box: RosterBox) -> Bool {
        switch box {
        case .inbox:
            switch attendee?.relation {
            case _ where client == nil:
                return false
            case _ where isGroup:
                return false
            case .invitedByAgent, .invitedBySystem:
                return true
            default:
                return false
            }
        case .my:
            switch attendee?.relation {
            case _ where client == nil:
                return false
            case _ where isGroup:
                return false
            case .attendee:
                return true
            default:
                return false
            }
        case .team:
            if case .team = attendee?.relation { return true }
            return false
        case .groups:
            return isGroup
        case .archive:
            return attendee == nil
        }
    }
    
    func typingContext() -> TypingContext {
        return .init(kind: .chat, ID: ID)
    }
    
    func transferredFrom() -> (agent: AgentEntity, comment: String?)? {
        guard let attendee = attendee else { return nil }
        guard case let .attendee(agent, toAssist, comment) = attendee.relation else { return nil }
        guard let a = agent, !toAssist else { return nil }
        return (a, comment)
    }

    func transferredTo() -> (agent: AgentEntity, comment: String?)? {
        guard let agent = m_transfer_to_agent, !agent.isMe else { return nil }
        guard !m_transfer_assisting else { return nil }
        guard let _ = m_transfer_date else { return nil }
        return (agent, m_transfer_comment)
    }

    func transferredToDepartment() -> (department: DepartmentEntity, agent: AgentEntity, comment: String?)? {
        guard let department = m_transfer_to_department else { return nil }
        guard let agent = m_transfer_to_agent, !agent.isMe else { return nil }
        guard !m_transfer_assisting else { return nil }
        guard let _ = m_transfer_date else { return nil }
        return (department, agent, m_transfer_comment)
    }

    func assistingFrom() -> (agent: AgentEntity, comment: String?)? {
        guard let attendee = attendee else { return nil }
        guard case let .attendee(agent, toAssist, comment) = attendee.relation else { return nil }
        guard let a = agent, toAssist else { return nil }
        return (a, comment)
    }

    func assistingTo() -> (agent: AgentEntity, comment: String?)? {
        guard let agent = m_transfer_to_agent, !agent.isMe else { return nil }
        guard m_transfer_assisting else { return nil }
        guard let _ = m_transfer_date else { return nil }
        return (agent, m_transfer_comment)
    }

    func selfJoined() -> Bool {
        guard let attendee = attendee else { return false }
        guard case let .attendee(agent, _, _) = attendee.relation else { return false }
        guard agent == nil else { return false }
        return true
    }
    
    func isTransferredAway() -> Bool {
        if let _ = m_transfer_date, !m_transfer_assisting {
            return true
        }
        else {
            return false
        }
    }
    
    func activeAttendees(withMe: Bool) -> [ChatAttendeeEntity] {
        let selfAttendee: [ChatAttendeeEntity]
        if withMe, let attendee = attendee, case .attendee = attendee.relation {
            selfAttendee = [attendee]
        }
        else {
            selfAttendee = []
        }
        
        let otherAttendees = attendees.filter {
            guard case .attendee = $0.relation else { return false }
            guard !($0.agent?.isMe == true) else { return false }
            return true
        }
        
        return selfAttendee + otherAttendees
    }
    
    func teamAttendees(withMe: Bool) -> [ChatAttendeeEntity] {
        let selfAttendee: [ChatAttendeeEntity]
        if withMe, let attendee = attendee, case .team = attendee.relation {
            selfAttendee = [attendee]
        }
        else {
            selfAttendee = []
        }
        
        let otherAttendees = attendees.filter {
            guard case .team = $0.relation else { return false }
            guard !($0.agent?.isMe == true) else { return false }
            return true
        }
        
        return selfAttendee + otherAttendees
    }
    
    func attendeeAssignment(for ID: Int) -> JVChatAttendeeAssignment {
        if attendee == nil, attendees.isEmpty {
            return .notPresented
        }
        else if attendee?.agent?.ID == ID {
            return .assignedWithMe
        }
        else if attendees.compactMap({ $0.agent?.ID }).contains(ID) {
            return .assignedWithMe
        }
        else {
            return .assignedToAnother
        }
    }

    var recipient: JVSenderData? {
        if let client = client {
            return JVSenderData(type: .client, ID: client.ID)
        }
        else if let agent = teamAttendees(withMe: false).first?.agent {
            return JVSenderData(type: .agent, ID: agent.ID)
        }
        else if let agent = attendee?.agent {
            return JVSenderData(type: .agent, ID: agent.ID)
        }
        else {
            return nil
        }
    }
    
    var notifyingCaptionStatus: String {
        guard let status = notifying else {
            return loc["Details.Group.EnableAlerts.On"]
        }
        
        switch status {
        case .nothing:
            return loc["Details.Group.EnableAlerts.Off"]
        case .everything:
            return loc["Details.Group.EnableAlerts.On"]
        case .mentions:
            return loc["Details.Group.EnableAlerts.Mentions"]
        }
    }
    
    var notifyingCaptionAction: String {
        guard let status = notifying else {
            return loc["Teambox.Options.Everything"]
        }
        
        switch status {
        case .everything:
            return loc["Teambox.Options.Everything"]
        case .nothing:
            return loc["Teambox.Options.Nothing"]
        case .mentions:
            return loc["Teambox.Options.Mentions"]
        }
    }
    
    var correspondingAgent: AgentEntity? {
        return b_agent
    }
    
    var isLive: Bool {
        guard let _ = client else { return false }
        guard !attendees.isEmpty else { return false }
        return true
    }
    
    var owningAgent: AgentEntity? {
        return m_owning_agent
    }
    
    func hasAttendee(agent: AgentEntity) -> Bool {
        for attendee in attendees {
            guard agent.ID == attendee.agent?.ID else { continue }
            return true
        }
        
        return false
    }
    
    func hasManagingAccess(agent: AgentEntity) -> Bool {
        guard isGroup && !(isMain) else { return false }
        if owningAgent?.ID == agent.ID { return true }
        if agent.isAdmin { return true }
        return false
    }
    
    func export() -> JVChatShortChange {
        return JVChatShortChange(
            ID: Int(m_id),
            client: m_client?.export(),
            attendee: m_attendee?.export(),
            teammateID: attendees.first?.agent?.ID,
            isGroup: m_is_group,
            title: m_title,
            about: m_about,
            icon: m_icon,
            isArchived: (m_attendee == nil))
    }
    
    func isAvailable(accepting: Bool, joining: Bool) -> Bool {
        switch attendee?.relation {
        case .invitedBySystem:
            return accepting
        case .invitedByAgent:
            return joining
        case .attendee:
            return true
        case .team:
            return true
        case nil:
            return true
        }
    }
}
