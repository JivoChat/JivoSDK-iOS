//
//  KeychainToken.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 19.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation


struct KeychainAccessing: OptionSet {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    static let hasLock = KeychainAccessing(rawValue: 1 << 0)
    static let unlockedOnce = KeychainAccessing(rawValue: 1 << 1)
    static let unlockedAtUse = KeychainAccessing(rawValue: 1 << 2)
    static let preventSync = KeychainAccessing(rawValue: 1 << 3)
    static let avoidCaching = KeychainAccessing(rawValue: 1 << 4)
}

struct KeychainToken {
    let key: String
    let hint: Any
    let accessing: KeychainAccessing
    
    init(key: String, hint: Any, accessing: KeychainAccessing) {
        self.key = key
        self.hint = hint
        self.accessing = accessing
    }
}

extension KeychainToken {
    static let deviceID = KeychainToken(key: "deviceID", hint: String.self, accessing: [.unlockedOnce, .preventSync])
    static let firstUseDate = KeychainToken(key: "firstUseDate", hint: Date.self, accessing: [.unlockedOnce])
    static let token = KeychainToken(key: "token", hint: String.self, accessing: [.unlockedOnce])
    static let vkToken = KeychainToken(key: "vkToken", hint: String.self, accessing: [.unlockedOnce])
    static let vkID = KeychainToken(key: "vkID", hint: String.self, accessing: [.unlockedOnce])
    static let tokenDate = KeychainToken(key: "tokenDate", hint: Date.self, accessing: [.unlockedOnce])
    static let siteID = KeychainToken(key: "siteID", hint: Int.self, accessing: [.unlockedOnce])
    static let shard = KeychainToken(key: "shard", hint: String.self, accessing: [.unlockedOnce])
    static let endpoint = KeychainToken(key: "endpoint", hint: String.self, accessing: [.unlockedOnce])
    static let sessionID = KeychainToken(key: "sessionID", hint: String.self, accessing: [.unlockedOnce])
    static let deviceLiveToken = KeychainToken(key: "deviceLiveToken", hint: String.self, accessing: [.unlockedOnce, .preventSync])
    static let sdkToken = KeychainToken(key: "sdkToken", hint: String.self, accessing: [.unlockedOnce])
}
