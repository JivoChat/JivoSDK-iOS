//
//  PushCredentialsEntity+Update.swift
//  App
//
//  Created by Stan Potemkin on 04.02.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension PushCredentialsEntity {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_str = m_id
        }
        
        if let c = change as? JVPushCredentialsChange {
            m_id = c.id
            m_endpoint = c.endpoint
            m_site_id = Int64(c.siteId)
            m_channel_id = c.channelId
            m_client_id = c.clientId
            m_device_id = c.deviceId
            m_device_live_token = c.deviceLiveToken
            m_date = c.date
            m_status = c.status.rawValue
        }
    }
}

final class JVPushCredentialsChange: JVDatabaseModelChange {
    let id: String
    let endpoint: String?
    let siteId: Int
    let channelId: String
    let clientId: String
    let deviceId: String
    let deviceLiveToken: String
    let status: PushCredentialsEntity.Status
    let date: Date

    override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_id", value: id)
    }

    init(
        id: String,
        endpoint: String?,
        siteId: Int,
        channelId: String,
        clientId: String,
        deviceId: String,
        deviceLiveToken: String,
        date: Date = Date(),
        status: PushCredentialsEntity.Status
    ) {
        self.id = id
        self.endpoint = endpoint
        self.siteId = siteId
        self.channelId = channelId
        self.clientId = clientId
        self.deviceId = deviceId
        self.deviceLiveToken = deviceLiveToken
        self.date = date
        self.status = status

        super.init()
    }

    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}
