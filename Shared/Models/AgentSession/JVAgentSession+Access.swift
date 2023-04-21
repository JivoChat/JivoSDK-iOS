//
//  JVAgentSession+Access.swift
//  App
//
//  Created by Stan Potemkin on 22.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

public enum JVAgentSessionWorkingState {
    case soon(JVAgentWorktimeDayMeta?)
    case active
    case expiring(JVAgentWorktimeDayConfig)
    case inactive(JVAgentWorktimeDayMeta?)
    case hidden
}

extension JVAgentSession {
    public var sessionID: String {
        return m_id.jv_orEmpty
    }
    
    public var email: String {
        return m_email.jv_orEmpty
    }
    
    public var isAdmin: Bool {
        return m_is_admin
    }
    
    public var isOperator: Bool {
        return m_is_operator
    }
    
    public var siteID: Int {
        return Int(m_site_id)
    }
    
    public var isActive: Bool {
        return m_is_active
    }
    
    public var channels: [JVChannel] {
        if let allObjects = m_channels.jv_orEmpty.allObjects as? [JVChannel] {
            return allObjects
        }
        else {
            assertionFailure()
            return Array()
        }
    }
    
    public var widgetChannels: [JVChannel] {
        return channels.filter { $0.jointType == nil }
    }
    
    public var priceListId: Int? {
        if m_global_pricelist_id > 0 {
            return Int(m_global_pricelist_id)
        }
        else {
            return nil
        }
    }
    
    public var allowMobileCalls: Bool {
        return m_allow_mobile_calls
    }
    
    public var voxCredentials: (login: String, password: String)? {
        guard let login = m_vox_login?.jv_valuable else { return nil }
        guard let password = m_vox_password?.jv_valuable else { return nil }
        return (login: login, password: password)
    }
    
    public var isWorking: Bool {
        return m_is_working
    }
    
    public var isWorkingHidden: Bool {
        return m_is_working_hidden
    }
    
    public func globalFeatures() -> JVAgentTechConfig {
        return JVAgentTechConfig(
            priceListId: (m_global_pricelist_id > 0 ? Int(m_global_pricelist_id) : nil),
            guestInsightEnabled: m_global_guests_insight_enabled,
            fileSizeLimit: Int(m_global_file_size_limit),
            disableArchiveForRegular: m_global_disable_archive_for_regular,
            iosTelephonyEnabled: m_global_received ? m_global_platform_telephony_enabled : nil,
            limitedCRM: m_global_limited_crm,
            assignedAgentEnabled: m_global_assigned_agent_enabled,
            messageEditingEnabled: m_global_message_editing_enabled,
            groupsEnabled: m_global_groups_enabled,
            mentionsEnabled: m_global_mentions_enabled,
            commentsEnabled: m_global_comments_enabled,
            reactionsEnabled: m_global_reactions_enabled,
            businessChatEnabled: m_global_business_chat_enabled,
            billingUpdateEnabled: m_global_billing_update_enabled,
            standaloneTasks: m_global_standalone_tasks_enabled,
            feedbackSdkEnabled: m_global_feedback_sdk_enabled,
            mediaServiceEnabled: m_global_media_service_enabled,
            voiceMessagesEnabled: m_global_voice_messages_enabled
        )
    }
    
    public func jointType(for channelID: Int) -> JVChannelJoint? {
        let channel = channels.first(where: { $0.ID == channelID })
        return channel?.jointType
    }
    
    public func testableChannels(domain: String, lang: JVLocaleLang, codeHost: String?) -> [(channel: JVChannel, url: URL)] {
        return channels.compactMap { channel in
            guard
                channel.isTestable,
                let link = channel.name.jv_valuable,
                let url = URL.jv_widgetSumulator(
                    domain: domain,
                    siteLink: link,
                    channelID: channel.publicID,
                    codeHost: codeHost,
                    lang: lang.rawValue)
            else { return nil }
            
            return (channel: channel, url: url)
        }
    }
    
    public static func obtainWorkingState(
        dayConfig: JVAgentWorktimeDayConfig?,
        nextMetaPair: JVAgentWorktimeDayMetaPair?,
        isWorking: Bool,
        isWorkingHidden: Bool
    ) -> JVAgentSessionWorkingState {
        func _hash(_ hour: Int, _ minute: Int) -> Int {
            return hour * 60 + minute
        }
        
        if isWorkingHidden {
            //            debug("{worktime} working-banner[hidden]")
            return .hidden
        }
        
        guard let dayConfig = dayConfig else {
//            debug("{worktime} working-banner[\(isWorking ? "active" : "hidden")]")
            return isWorking ? .active : .hidden
        }
        
        let hour = JVActiveLocale().calendar.component(.hour, from: Date())
        let minute = JVActiveLocale().calendar.component(.minute, from: Date())
        let nowHash = _hash(hour, minute)
        let startHash = _hash(dayConfig.startHour, dayConfig.startMinute)
        let expiringHash = _hash(dayConfig.endHour, dayConfig.endMinute) - 30
        let endHash = _hash(dayConfig.endHour, dayConfig.endMinute)
        
        if isWorking {
            if expiringHash <= nowHash, nowHash < endHash {
//                debug("{worktime} working-banner[expiring]")
                return .expiring(dayConfig)
            }
            else {
//                debug("{worktime} working-banner[active]")
                return .active
            }
        }
        else {
            if dayConfig.enabled, nowHash < startHash {
//                debug("{worktime} working-banner[soon]")
                return .soon(nextMetaPair?.today)
            }
            else {
//                debug("{worktime} working-banner[inactive]")
                return .inactive(nextMetaPair?.anotherDay)
            }
        }
    }
}
