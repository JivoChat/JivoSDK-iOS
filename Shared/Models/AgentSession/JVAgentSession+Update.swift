//
//  JVAgentSession+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVAgentSession {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_str = m_id
        }
        
        if let c = change as? JVAgentSessionGeneralChange {
            m_id = c.sessionID
            m_site_id = Int32(c.siteID)
            m_email = c.email
            m_is_admin = c.isAdmin
            m_is_operator = c.isOperator
            m_is_active = true
            m_vox_login = c.voxLogin
            m_vox_password = c.voxPassword
            m_allow_mobile_calls = c.mobileCalls
            m_is_working = c.workingState
        }
        else if let c = change as? JVAgentSessionContextChange {
            if let features = c.techConfig {
                m_global_received = true
                m_global_pricelist_id = Int16(c.pricelistID ?? 0)
                m_global_guests_insight_enabled = features.guestInsightEnabled
                m_global_file_size_limit = Int16(features.fileSizeLimit)
                m_global_disable_archive_for_regular = features.disableArchiveForRegular
                m_global_platform_telephony_enabled = features.iosTelephonyEnabled ?? true
                m_global_limited_crm = features.limitedCRM
                m_global_assigned_agent_enabled = features.assignedAgentEnabled
                m_global_message_editing_enabled = features.messageEditingEnabled
                m_global_groups_enabled = features.groupsEnabled
                m_global_mentions_enabled = features.mentionsEnabled
                m_global_comments_enabled = features.commentsEnabled
                m_global_reactions_enabled = features.reactionsEnabled
                m_global_business_chat_enabled = features.businessChatEnabled
                m_global_billing_update_enabled = features.billingUpdateEnabled
                m_global_standalone_tasks_enabled = features.standaloneTasks
                m_global_feedback_sdk_enabled = features.feedbackSdkEnabled
                m_global_media_service_enabled = features.mediaServiceEnabled
                m_global_voice_messages_enabled = features.voiceMessagesEnabled
            }
        }
        else if let c = change as? JVAgentSessionMobileCallsChange {
            m_allow_mobile_calls = c.enabled
        }
        else if let c = change as? JVAgentSessionWorktimeChange {
            m_is_working = c.isWorking ?? m_is_working
            m_is_working_hidden = c.isWorkingHidden
        }
        else if let c = change as? JVAgentSessionChannelsChange {
            e_channels.setSet(Set(context.upsert(of: JVChannel.self, with: c.channels)))
        }
        else if let c = change as? JVAgentSessionChannelUpdateChange {
            let oldChannels = Array(channels.filter { $0.ID != c.channel.ID })
            
            if let newChannel = context.upsert(of: JVChannel.self, with: c.channel) {
                e_channels.setSet(Set(oldChannels + [newChannel]))
            }
            else {
                e_channels.setSet(Set(oldChannels))
            }
        }
        else if let c = change as? JVAgentSessionChannelRemoveChange {
            let oldChannels = Array(channels.filter { $0.ID == c.channelId })
            let needChannels = Array(channels.filter { $0.ID != c.channelId })
            
            e_channels.setSet(Set(needChannels))
            context.customRemove(objects: oldChannels, recursive: true)
        }
    }
    
    private var e_channels: NSMutableSet {
        return mutableSetValue(forKeyPath: #keyPath(JVAgentSession.m_channels))
    }
}
