//
//  JVTask+Access.swift
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
    var iconName: String? {
        switch self {
        case .unknown: return nil
        case .active: return "reminder_active"
        case .fired: return "reminder_fired"
        }
    }
}

extension JVTask {
    var ID: Int {
        return Int(m_id)
    }
    
    var siteID: Int {
        return Int(m_site_id)
    }
    
    var clientID: Int {
        return Int(m_client_id)
    }
    
    var client: JVClient? {
        return m_client
    }
    
    var agent: JVAgent? {
        return m_agent
    }
    
    var text: String? {
        return m_text?.jv_valuable
    }
    
    var notifyAt: Date {
        return Date(timeIntervalSince1970: m_notify_timstamp)
    }
    
    var status: JVTaskStatus {
        return JVTaskStatus(rawValue: m_status.jv_orEmpty) ?? .unknown
    }
    
    var iconName: String? {
        switch status {
        case .active:
            return "reminder_active"
        case .fired:
            return "reminder_fired"
        case .unknown:
            return nil
        }
    }
    
    func convertToMessageBody() -> JVMessageBodyTask {
        return JVMessageBodyTask(
            taskID: Int(m_id),
            agent: m_agent,
            text: m_text.jv_orEmpty,
            createdAt: Date(timeIntervalSince1970: m_created_timestamp),
            updatedAt: Date(timeIntervalSince1970: m_modified_timestamp),
            transitionedAt: Date(timeIntervalSince1970: m_modified_timestamp),
            notifyAt: Date(timeIntervalSince1970: m_notify_timstamp),
            status: JVMessageBodyTaskStatus(rawValue: m_status.jv_orEmpty) ?? .fired
        )
    }
}
