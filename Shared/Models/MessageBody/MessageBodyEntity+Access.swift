//
//  MessageBodyEntity+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

enum JVMessageBodyCallType: String {
    case callback = "callback"
    case incoming = "incoming"
    case outgoing = "outgoing"
    case unknown
    
    var isIncoming: Bool {
        switch self {
        case .callback: return false
        case .incoming: return true
        case .outgoing: return false
        case .unknown: return true
        }
    }
}

enum JVMessageBodyCallEndCallSide: String {
    case from = "from"
    case to = "to"
}

enum JVMessageBodyCallEvent: String {
    case start = "start"
    case agentConnecting = "agent_connecting"
    case agentConnected = "agent_connected"
    case agentDisconnected = "agent_disconnected"
    case clientConnected = "client_connected"
    case error = "error"
    case retry = "retry"
    case end = "end"
    case unknown
}

enum JVMessageBodyCallReason: String {
    case isBusy = "is_busy"
    case allBusy = "all_busy"
    case invalidNumber = "invalid_number"
    case unknown
}

struct JVMessageBodyConference {
    let url: URL?
    let title: String
}

struct JVMessageBodyStory {
    let text: String
    let fileName: String
    let thumb: URL?
    let file: URL?
    let title: String
}

enum JVMessageBodyContactFormStatus: String {
    case inactive
    case editable
    case syncing
    case snapshot
}

enum JVMessageBodyTaskStatus: String {
    case created = "created"
    case updated = "updated"
    case completed = "completed"
    case deleted = "deleted"
    case fired = "fired"
    case unknown

    var isFinished: Bool {
        switch self {
        case .created: return false
        case .updated: return false
        case .completed: return true
        case .deleted: return true
        case .fired: return true
        case .unknown: return false
        }
    }
}

struct JVMessageBodyEmail {
    let from: String
    let to: String
    let subject: String
}

struct JVMessageBodyTransfer {
    let agent: AgentEntity?
    let department: DepartmentEntity?
}

struct JVMessageBodyInvite {
    let by: AgentEntity?
    let comment: String?
}

struct JVMessageBodyCall {
    let callID: String
    let agent: AgentEntity?
    let type: JVMessageBodyCallType
    let phone: String?
    let event: JVMessageBodyCallEvent
    let endCallSide: JVMessageBodyCallEndCallSide?
    let reason: JVMessageBodyCallReason?
    let recordLink: String?

    var recordURL: URL? {
        if let link = recordLink {
            return URL(string: link)
        }
        else {
            return nil
        }
    }

    var isFailed: Bool {
        return (event == .error)
    }
}

struct JVMessageBodyTask {
    let taskID: Int
    let agent: AgentEntity?
    let isImportant: Bool
    let text: String
    let createdAt: Date?
    let updatedAt: Date?
    let transitionedAt: Date?
    let notifyAt: Date
    let status: JVMessageBodyTaskStatus
}

struct JVMessageBodyOrder {
    let orderID: String
    let email: String?
    let phone: String?
    let subject: String
    let text: String
}

extension MessageBodyEntity {
    var email: JVMessageBodyEmail? {
        guard let from = m_from?.jv_valuable else { return nil }
        guard let to = m_to?.jv_valuable else { return nil }

        return JVMessageBodyEmail(
            from: from,
            to: to,
            subject: m_subject.jv_orEmpty
        )
    }
    
    var transfer: JVMessageBodyTransfer? {
        guard m_agent != nil || m_department != nil
        else {
            return nil
        }
        
        return JVMessageBodyTransfer(
            agent: m_agent,
            department: m_department
        )
    }
    
    var invite: JVMessageBodyInvite? {
        return JVMessageBodyInvite(
            by: m_agent,
            comment: m_text
        )
    }
    
    var call: JVMessageBodyCall? {
        guard let event = m_event?.jv_valuable else { return nil }
        guard let callID = m_call_id?.jv_valuable else { return nil }
        guard let type = m_type?.jv_valuable else { return nil }
        
        return JVMessageBodyCall(
            callID: callID,
            agent: m_agent,
            type: JVMessageBodyCallType(rawValue: type) ?? .unknown,
            phone: m_phone?.jv_valuable,
            event: JVMessageBodyCallEvent(rawValue: event) ?? .unknown,
            endCallSide: m_end_call_side?.jv_valuable.flatMap(JVMessageBodyCallEndCallSide.init),
            reason: m_reason?.jv_valuable.flatMap(JVMessageBodyCallReason.init),
            recordLink: m_record_link?.jv_valuable
        )
    }

    var task: JVMessageBodyTask? {
        guard
            m_task_id > 0,
            let agent = m_agent,
            let notifyAt = m_notify_at
        else { return nil }

        return JVMessageBodyTask(
            taskID: Int(m_task_id),
            agent: agent,
            isImportant: m_is_important,
            text: m_text ?? String(),
            createdAt: m_created_at,
            updatedAt: m_updated_at,
            transitionedAt: m_transitioned_at,
            notifyAt: notifyAt,
            status: m_status.flatMap(JVMessageBodyTaskStatus.init) ?? .fired
        )
    }
    
    var text: String? {
        return m_text
    }
    
    var buttons: [String] {
        return m_buttons?.jv_valuable?.components(separatedBy: "\n") ?? []
    }
    
    var order: JVMessageBodyOrder? {
        guard
            let orderID = m_order_id?.jv_valuable,
            let subject = m_subject?.jv_valuable,
            let text = m_text?.jv_valuable
        else { return nil }
        
        return JVMessageBodyOrder(
            orderID: orderID,
            email: m_email,
            phone: m_phone,
            subject: subject,
            text: text
        )
    }
    
    var status: String? {
        return m_event
    }
}
