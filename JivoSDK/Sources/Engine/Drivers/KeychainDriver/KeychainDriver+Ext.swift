//
//  KeychainDriver.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 12.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import KeychainSwift

enum PushNotificationsCredentialsKeychainField: String {
    case siteId
    case channelId
    case clientId
    case deviceId
    case deviceLiveToken
}

extension KeychainToken {
    static let channelId = KeychainToken(key: "channelId", hint: String.self, accessing: [.unlockedOnce])
    static let sessionId = KeychainToken(key: "sessionId", hint: String.self, accessing: [.unlockedOnce])
    static let clientId = KeychainToken(key: "clientId", hint: String.self, accessing: [.unlockedOnce])
    static let chatLastSyncDate = KeychainToken(key: "chatLastSyncDate", hint: Date.self, accessing: [.unlockedOnce])
    static let connectionUrlPath = KeychainToken(key: "connectionUrlPath", hint: String.self, accessing: [.unlockedOnce])
    static let lastSeenMessageId = KeychainToken(key: "lastSeenMessageId", hint: Int.self, accessing: [.unlockedOnce])
}

extension IKeychainDriver {
    func userScope() -> IKeychainDriver {
        return scope(retrieveAccessor(forToken: .currentUserNamespace).string.jv_orEmpty)
    }
}
