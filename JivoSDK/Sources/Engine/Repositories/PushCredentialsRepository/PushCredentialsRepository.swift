//
//  PushCredentialsRepository.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 20.08.2022.
//

import Foundation
import JivoFoundation


final class PushCredentialsRepository: PersistentRepository<String, SdkClientSubPusherCredentials, JVPushCredentialsChange, JVPushCredentials, String> {
    private let databaseDriver: JVIDatabaseDriver
    
    init(databaseDriver: JVIDatabaseDriver) {
        self.databaseDriver = databaseDriver
        
        super.init(
            memoryRepository: MemoryRepository(indexItemsBy: \.id),
            databaseDriver: databaseDriver,
            changeFromItem: { item in
                return JVPushCredentialsChange(
                    id: item.id,
                    siteId: item.siteId,
                    channelId: item.channelId,
                    clientId: item.clientId,
                    deviceId: item.deviceId,
                    deviceLiveToken: item.deviceLiveToken,
                    date: item.date,
                    status: {
                        switch item.status {
                        case .active:
                            return .active
                        case .waitingForSubscribe:
                            return .waitingForRegister
                        case .waitingForUnsubscribe:
                            return .waitingForUnregister
                        }
                    }()
                )
            },
            itemFromModel: { model in
                return SdkClientSubPusherCredentials(
                    siteId: model.siteId,
                    channelId: model.channelId,
                    clientId: model.clientId,
                    deviceId: model.deviceId,
                    deviceLiveToken: model.deviceLiveToken,
                    date: model.date,
                    status: {
                        switch model.status {
                        case .active:
                            return .active
                        case .waitingForRegister:
                            return .waitingForSubscribe
                        case .waitingForUnregister:
                            return .waitingForUnsubscribe
                        case .unknown:
                            return .waitingForUnsubscribe
                        }
                    }()
                )
            },
            mainKeyFromIndex: { index in
                return JVDatabaseModelCustomId<String>(key: "m_id", value: index)
            },
            updateHandler: { _ in
            }
        )
    }
}
