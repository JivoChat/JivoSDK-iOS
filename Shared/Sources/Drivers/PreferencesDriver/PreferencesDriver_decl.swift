//
//  PreferencesDriver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 02/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

struct PreferencesToken {
    let key: String
    let hint: Any
}

extension PreferencesToken {
    static let initialLaunchDate = PreferencesToken(key: "initialLaunchDate", hint: Date.self)
    static let server = PreferencesToken(key: "server", hint: String.self)
    static let sdkServer = PreferencesToken(key: "sdkServer", hint: String.self)
    static let sdkSiteID = PreferencesToken(key: "sdkSiteID", hint: Int.self)
    static let sdkChannelId = PreferencesToken(key: "sdkChannelId", hint: String.self)
    static let installationID = PreferencesToken(key: "installationID", hint: String.self)
    static let deviceLiveToken = PreferencesToken(key: "deviceLiveToken", hint: String.self)
    static let activeLocale = PreferencesToken(key: "activeLocale", hint: Locale.self)
    static let vibroEnabled = PreferencesToken(key: "vibroEnabled", hint: Bool.self)
    static let cannedPhrasesEnabled = PreferencesToken(key: "cannedPhrasesEnabled", hint: Bool.self)
    static let aiRephraseToggleEnabled = PreferencesToken(key: "aiRephraseToggleEnabled", hint: Bool.self)
}

protocol IPreferencesDriver: AnyObject {
    var signal: JVBroadcastTool<Void> { get }
    func migrate(keys: [String])
    func register(defaults: [String: Any])
    func detectFirstLaunch() -> Bool
    func retrieveAccessor(forToken token: PreferencesToken) -> IPreferencesAccessor
    func clearAll()
}
