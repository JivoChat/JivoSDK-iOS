//
//  JVTask+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

public enum JVTaskStatus: String {
    case unknown
    case active = "active"
    case fired = "fired"
    public var iconName: String? {
        switch self {
        case .unknown: return nil
        case .active: return "reminder_active"
        case .fired: return "reminder_fired"
        }
    }
}

extension JVTask {
    public var ID: Int {
        return Int(m_id)
    }
    
    public var siteID: Int {
        return Int(m_site_id)
    }
    
    public var clientID: Int {
        return Int(m_client_id)
    }
    
    public var client: JVClient? {
        return m_client
    }
    
    public var agent: JVAgent? {
        return m_agent
    }
    
    public var text: String? {
        return m_text?.jv_valuable
    }
    
    public var notifyAt: Date {
        return Date(timeIntervalSince1970: m_notify_timstamp)
    }
    
    public var status: JVTaskStatus {
        return JVTaskStatus(rawValue: m_status.jv_orEmpty) ?? .unknown
    }
    
    public var iconName: String? {
        switch status {
        case .active:
            return "reminder_active"
        case .fired:
            return "reminder_fired"
        case .unknown:
            return nil
        }
    }
    
    public func convertToMessageBody() -> JVMessageBodyTask {
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