//
//  JVGuest+Access.swift
//  App
//
//  Created by Stan Potemkin on 16.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMRepicKit

public enum JVGuestStatus {
    case online
    case proactive(agent: JVAgent)
    case invited
    case chatting(withMe: Bool)
    case calling(withMe: Bool)
}

extension JVGuest: JVDisplayable {
    public var senderType: JVSenderType {
        return .guest
    }

    public var ID: String {
        return m_id.jv_orEmpty
    }

    public var channel: JVChannel? {
        abort()
    }
    
    public var channelID: String {
        return m_channel_id.jv_orEmpty
    }
    
    public var agentID: Int {
        return Int(m_agent_id)
    }
    
    public var status: JVGuestStatus {
        switch m_status {
        case "on_site":
            return .online
            
        case "proactive_show":
            return m_proactive_agent.flatMap(JVGuestStatus.proactive) ?? .online
            
        case "invite_sent":
            return .invited
            
        case "on_chat":
            let me = attendees.first(where: { $0.agent?.ID == Int(m_agent_id) })
            return .chatting(withMe: me != nil)
            
        case "on_call":
            let me = attendees.first(where: { $0.agent?.ID == Int(m_agent_id) })
            return .calling(withMe: me != nil)
            
        default:
            /*assertionFailure();*/
            return .online
        }
    }
    
    public var clientID: Int? {
        return (m_client_id > 0 ? Int(m_client_id) : nil)
    }
    
    public var isMe: Bool {
        return false
    }

    public var countryCode: String? {
        return m_country_code?.jv_valuable?.lowercased()
    }
    
    public var countryName: String? {
        return m_country_name?.jv_valuable
    }
    
    public var regionName: String? {
        return m_region_name?.jv_valuable
    }
    
    public var cityName: String? {
        return m_city_name?.jv_valuable
    }
    
    public var organization: String? {
        return m_organization?.jv_valuable
    }
    
    public var lastIP: String? {
        return m_source_ip?.jv_valuable
    }
    
    public func displayName(kind: JVDisplayNameKind) -> String {
        switch kind {
        case .original where m_name.jv_orEmpty.isEmpty:
            let defaultPrefix = loc["Visitor.Title"]
            let prefix = cityName ?? regionName ?? countryName ?? defaultPrefix
            return (m_client_id > 0 ? "\(prefix) \(m_client_id)" : prefix)
        case .original:
            return m_name.jv_orEmpty
        case .short:
            return displayName(kind: .original)
        case .decorative:
            return displayName(kind: .original)
        case .relative:
            return String()
        }
    }

    public func repicItem(transparent: Bool, scale: CGFloat?) -> JMRepicItem? {
        if let man = managedObjectContext {
            man.userInfo.setObject("hello", forKey: "okay" as NSString)
        }
        
        if m_client_id > 0, let client = jv_retrieveClient(id: Int(m_client_id)) {
            let item = client.repicItem(transparent: false, scale: scale)
            return item
        }
        else if let avatarID = String(m_id.jv_orEmpty.dropLast(3)).jv_toHexInt() {
            let c = URL.jv_generateAvatarURL(ID: avatarID)
            let image = JMRepicItemSource.avatar(URL: nil, image: c.image, color: c.color, transparent: transparent)
            return JMRepicItem(backgroundColor: nil, source: image, scale: scale ?? 1.0, clipping: .dual)
        }
        else {
            return nil
        }
    }
    
    public var phone: String? {
        return m_phone?.jv_valuable
    }
    
    public var email: String? {
        return m_email?.jv_valuable
    }
    
    public var integration: JVChannelJoint? {
        return nil
    }
    
    public var hashedID: String {
        return "guest:\(ID)"
    }

    public var isAvailable: Bool {
        return true
    }

    public var pageURL: URL? {
        if let url = m_page_link.flatMap(URL.init) {
            return url
        }
        else {
            return nil
        }
    }
    
    public var pageTitle: String {
        return m_page_title?.jv_valuable ?? m_page_link ?? String()
    }
    
    public var startDate: Date? {
        return m_start_date
    }
    
    public var UTM: JVClientSessionUtm? {
        return m_utm
    }
    
    public var visitsNumber: Int {
        return Int(m_visits_number)
    }
    
    public var navigatesNumber: Int {
        return Int(m_navigates_number)
    }
    
    public var isVisible: Bool {
        return m_visible
    }

    public var attendees: [JVChatAttendee] {
        if let allObjects = m_attendees?.allObjects as? [JVChatAttendee] {
            return allObjects
        }
        else {
            assertionFailure()
            return Array()
        }
    }
    
    public var bots: [JVBot] {
        if let allObjects = m_bots?.allObjects as? [JVBot] {
            return allObjects
        }
        else {
            assertionFailure()
            return Array()
        }
    }
    
    public func proactiveAgent() -> JVAgent? {
        if case .proactive = status {
            return m_proactive_agent
        }
        else {
            return nil
        }
    }
    
    public var lastUpdate: Date {
        return m_last_update ?? Date(timeIntervalSinceReferenceDate: 0)
    }
    
    public var hasBasicInfo: Bool {
        if m_start_date == nil { return false }
        return true
    }
    
    public var disappearDate: Date? {
        return m_disappear_date
    }
}

extension JVGuestStatus {
    public var iconName: String {
        switch self {
        case .online: return "vi_onsite"
        case .proactive: return "vi_proactive"
        case .invited: return "vi_invite"
        case .chatting: return "vi_onchat"
        case .calling: return "vi_oncall"
        }
    }
    
    public var title: String {
        switch self {
        case .online: return loc["Details.Visitor.Onsite"]
        case .proactive: return loc["Details.Visitor.Proactive"]
        case .invited: return loc["Details.Visitor.Invited"]
        case .chatting: return loc["Details.Visitor.Onchat"]
        case .calling: return loc["Details.Visitor.Oncall"]
        }
    }
}
