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
            m_is_owner = c.isOwner
            m_is_admin = c.isAdmin
            m_is_supervisor = c.isSupervisor
            m_is_operator = c.isOperator
            m_is_active = true
            m_vox_login = c.voxLogin
            m_vox_password = c.voxPassword
            m_allow_mobile_calls = c.mobileCalls
            m_is_working = c.workingState
        }
        else if let c = change as? JVAgentSessionContextChange {
            m_global_pricelist_id = Int16(c.pricelistID ?? 0)
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
