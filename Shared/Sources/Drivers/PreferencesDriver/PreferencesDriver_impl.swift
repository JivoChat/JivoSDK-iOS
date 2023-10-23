//
//  PreferencesDriver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 02/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

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
}
