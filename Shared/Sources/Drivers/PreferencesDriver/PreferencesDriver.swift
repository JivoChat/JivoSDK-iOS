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
    
    init(key: String, hint: Any) {
        self.key = key
        self.hint = hint
    }
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
}

protocol IPreferencesDriver: AnyObject {
    var signal: JVBroadcastTool<Void> { get }
    func migrate(keys: [String])
    func register(defaults: [String: Any])
    func detectFirstLaunch() -> Bool
    func retrieveAccessor(forToken token: PreferencesToken) -> IPreferencesAccessor
    func clearAll()
}

class PreferencesDriver: IPreferencesDriver {
    let storage: UserDefaults
    let namespace: String
    
    let signal = JVBroadcastTool<Void>()
    
    private let alreadyLaunchedKey = "alreadyLaunchedKey"
    
    init(storage: UserDefaults, namespace: String) {
        self.storage = storage
        self.namespace = namespace
    }
    
    func migrate(keys: [String]) {
        for key in keys {
            guard let object = storage.object(forKey: key) else { continue }
            storage.set(object, forKey: constructPath(key))
            storage.removeObject(forKey: key)
        }
    }
    
    func register(defaults: [String: Any]) {
        storage.register(defaults: defaults)
    }

    final func detectFirstLaunch() -> Bool {
        if storage.bool(forKey: constructPath(alreadyLaunchedKey)) {
            return false
        }
        else {
            storage.set(true, forKey: constructPath(alreadyLaunchedKey))
            storage.synchronize()
            return true
        }
    }
    
    final func retrieveAccessor(forToken token: PreferencesToken) -> IPreferencesAccessor {
        let path = constructPath(token.key)
        return PreferencesAccessor(storage: storage, key: path)
    }
    
//    final func baseURL(module: String) -> URL {
//        let defaultValue = URL(string: "https://\(module).jivosite.com")!
//
//        if let prefix = retrieveAccessor(forToken: .devserverPrefix).string, !prefix.isEmpty {
//            return URL(string: "https://\(module).\(prefix).dev.jivosite.com") ?? defaultValue
//        }
//        else {
//            return defaultValue
//        }
//    }
    
    func clearAll() {
        for key in storage.dictionaryRepresentation().keys {
            storage.removeObject(forKey: key)
        }
    }
    
    private func constructPath(_ key: String) -> String {
        return namespace.isEmpty ? key : "\(namespace):\(key)"
    }
    
    private func notify() {
        signal.broadcast(())
    }
}
