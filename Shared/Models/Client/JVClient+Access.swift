//
//  JVClient+Access.swift
//  App
//
//  Created by Stan Potemkin on 16.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMRepicKit

public struct JVClientProfile {
    public let emailByClient: String?
    public let emailByAgent: String?
    public let phoneByClient: String?
    public let phoneByAgent: String?
    public let comment: String?
    public let countryName: String?
    public let cityName: String?
    
    public var hasEmail: Bool {
        if let _ = emailByClient { return true }
        if let _ = emailByAgent { return true }
        return false
    }
    
    public var primaryPhone: String? {
        return phoneByAgent ?? phoneByClient
    }
}

extension JVClient: JVDisplayable {
    public var senderType: JVSenderType {
        return .client
    }

    public var ID: Int {
        return Int(m_id)
    }
    
    public var publicID: String {
        return m_public_id.jv_orEmpty
    }
    
    public var chatID: Int? {
        if m_chat_id > .zero {
            return Int(m_chat_id)
        }
        else {
            return nil
        }
    }
    
    public var channelID: Int {
        return Int(m_channel_id)
    }
    
    public var channel: JVChannel? {
        return m_channel
    }

    public var isMe: Bool {
        return false
    }

    public func displayName(kind: JVDisplayNameKind) -> String {
        switch kind {
        case .original where m_display_name.jv_orEmpty.isEmpty:
            return loc[format: "Client.Title", m_id]
        case .original:
            return m_display_name.jv_orEmpty
        case .short:
            return displayName(kind: .original)
        case .decorative:
            return displayName(kind: .original)
        case .relative:
            return String()
        }
    }
    
    public func repicItem(transparent: Bool, scale: CGFloat?) -> JMRepicItem? {
        let url = m_avatar_link.flatMap(URL.init)
        
        if let avatarID = String(m_guest_id.jv_orEmpty.dropLast(3)).jv_toHexInt() {
            let c = URL.jv_generateAvatarURL(ID: avatarID)
            let image = JMRepicItemSource.avatar(URL: url, image: c.image, color: c.color, transparent: transparent)
            return JMRepicItem(backgroundColor: nil, source: image, scale: scale ?? 1.0, clipping: .dual)
        }
        else {
            let c = URL.jv_generateAvatarURL(ID: UInt64(m_id))
            let image = JMRepicItemSource.avatar(URL: url, image: c.image, color: c.color, transparent: transparent)
            return JMRepicItem(backgroundColor: nil, source: image, scale: scale ?? 1.0, clipping: .dual)
        }
    }
    
    public var profile: JVClientProfile {
        return JVClientProfile(
            emailByClient: m_email_by_client,
            emailByAgent: m_email_by_agent,
            phoneByClient: m_phone_by_client,
            phoneByAgent: m_phone_by_agent,
            comment: m_comment,
            countryName: m_active_session?.geo?.country,
            cityName: m_active_session?.geo?.city
        )
    }
    
    public var visitsNumber: Int {
        return max(1, Int(m_visits_number))
    }
    
    public func assignedAgent() -> JVAgent? {
        return m_assigned_agent
    }
    
    public var navigatesNumber: Int {
        return max(1, Int(m_navigates_number))
    }
    
    public var session: JVClientSession? {
        switch integration {
        case .none:
            return m_active_session
        case .some(let joint):
            return joint.isStandalone ? nil : m_active_session
        }
    }
    
    public var customData: [JVClientCustomField] {
        if let allObjects = m_custom_data?.allObjects as? [JVClientCustomField] {
            return allObjects
        }
        else {
            return Array()
        }
    }
    
//    var proactiveRule: _JVClientProactiveRule? {
//        return _proactiveRule
//    }
    
    public var isOnline: Bool {
        if m_is_online {
            return true
        }
        else if m_channel?.jointType != nil {
            return true
        }
        else if m_channel?.jointType == JVChannelJoint.tel {
            return true
        }
        else {
            return false
        }
    }
    
    public var displayAsOnline: Bool {
        if m_is_online {
            return true
        }
            
        if channel?.jointType == nil, profile.hasEmail {
            return true
        }
        
        return false
    }
    
    public var hasIntegration: Bool {
        return (integration != nil)
    }
    
    public var integration: JVChannelJoint? {
        if let joint = channel?.jointType {
            return joint
        }
        else if let integration = m_integration?.jv_valuable {
            return JVChannelJoint(rawValue: integration)
        }
        else {
            return nil
        }
    }
    
    public var hashedID: String {
        return "client:\(ID)"
    }

    public var isAvailable: Bool {
        return true
    }

    public var integrationURL: URL? {
        if let link = m_integration_link {
            return URL(string: link)
        }
        else {
            return nil
        }
    }
    
    public var requiresEmail: Bool {
        guard channel?.jointType == JVChannelJoint.tel
        else {
            return false
        }
        
        return !profile.hasEmail
    }
    
    public var hasActiveCall: Bool {
        return m_has_active_call
    }

    public var task: JVTask? {
        return m_task
    }
    
    public var countryCode: String? {
        return m_active_session?.geo?.countryCode
    }
    
    public var isBlocked: Bool {
        return m_is_blocked
    }
    
    public func export() -> JVClientShortChange {
        return JVClientShortChange(
            ID: ID,
            channelID: channel?.ID,
            task: nil
        )
    }
}
