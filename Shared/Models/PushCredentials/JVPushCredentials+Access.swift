//
//  JVPushCredentials+Access.swift
//  App
//
//  Created by Stan Potemkin on 04.02.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension JVPushCredentials {
    enum Status: String {
        case active
        case waitingForRegister
        case waitingForUnregister
        case unknown
    }
}

extension JVPushCredentials {
    var siteId: Int {
        return Int(m_site_id)
    }
    
    var channelId: String {
        return m_channel_id.jv_orEmpty
    }
    
    var clientId: String {
        return m_client_id.jv_orEmpty
    }
    
    var deviceId: String {
        return m_device_id.jv_orEmpty
    }
    
    var deviceLiveToken: String {
        return m_device_live_token.jv_orEmpty
    }
    
    var date: Date {
        return m_date ?? Date()
    }
    
    var status: Status {
        return Status(rawValue: m_status.jv_orEmpty) ?? .unknown
    }
}
