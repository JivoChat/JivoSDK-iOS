//
//  TaskEntity+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

enum JVTaskStatus: String {
    case unknown
    case active = "active"
    case fired = "fired"
    case completed = "completed"
    case deleted = "deleted"
}

extension TaskEntity {
    var ID: Int {
        return Int(m_id)
    }
    
    var siteID: Int {
        return Int(m_site_id)
    }
    
    var clientID: Int {
        return Int(m_client_id)
    }
    
    var client: ClientEntity? {
        return m_client
    }
    
    var agent: AgentEntity? {
        return m_agent
    }
    
    var text: String? {
        return m_text?.jv_valuable
    }
    
    var notifyAt: Date {
        return Date(timeIntervalSince1970: m_notify_timestamp)
    }
    
    var status: JVTaskStatus {
        return JVTaskStatus(rawValue: m_status.jv_orEmpty) ?? .unknown
    }
    
    var isImportant: Bool {
        return m_is_important
    }
    
    var iconName: String? {
        switch status {
        case .active:
            return "reminder_active"
        case .fired:
            return "reminder_fired"
        case .unknown:
            return nil
        case .completed:
            return nil
        case .deleted:
            return nil
        }
    }
    
    func convertToMessageBody() -> JVMessageBodyTask {
        return JVMessageBodyTask(
            taskID: Int(m_id),
            agent: m_agent,
            isImportant: m_is_important,
            text: m_text.jv_orEmpty,
            createdAt: Date(timeIntervalSince1970: m_created_timestamp),
            updatedAt: Date(timeIntervalSince1970: m_modified_timestamp),
            transitionedAt: Date(timeIntervalSince1970: m_modified_timestamp),
            notifyAt: Date(timeIntervalSince1970: m_notify_timestamp),
            status: JVMessageBodyTaskStatus(rawValue: m_status.jv_orEmpty) ?? .fired
        )
    }
}
