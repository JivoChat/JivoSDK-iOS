//
//  KeychainDriver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 14/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import KeychainSwift

class KeychainDriver: IKeychainDriver {
    private let storage: KeychainSwift
    private let namespace: String
    
    init(storage: KeychainSwift, namespace: String) {
        self.storage = storage
        self.namespace = namespace
    }
    
    var lastOperationFailure: OSStatus? {
        let code = storage.lastResultCode
        return (code == errSecSuccess ? nil : code)
    }
    
    final func retrieveAccessor(forToken token: KeychainToken) -> IKeychainAccessor {
        let options = convertToOptions(accessing: token.accessing)
        return KeychainAccessor(storage: storage, namespace: namespace, scope: nil, key: token.key, options: options)
    }
    
    func migrate(mapping: [(String, KeychainSwiftAccessOptions)]) {
        for (key, options) in mapping {
            guard let data = storage.getData(key) else { continue }
            storage.delete(key)
            storage.set(data, forKey: constructPath(key: key), withAccess: options)
        }
    }
    
    func scope(_ name: String) -> IKeychainDriver {
        let path = [namespace, name].joined(separator: ":")
        return KeychainDriver(storage: storage, namespace: path)
    }
    
    final func clearNamespace(scopePrefix: String) {
        if namespace.isEmpty {
            storage.clear()
        }
        else {
            let prefix = constructPath(key: scopePrefix)
            storage.allKeys
                .filter { $0.hasPrefix(prefix) }
                .forEach { storage.delete($0) }
        }
    }
    
    final func clearAll() {
        storage.clear()
    }
    
    private func constructPath(key: String) -> String {
        let parts: [String?] = [(namespace.isEmpty ? nil : namespace), key]
        return parts.compactMap({$0}).joined(separator: ":")
    }
    
    private func convertToOptions(accessing: KeychainAccessing) -> KeychainSwiftAccessOptions {
        if accessing.contains(.unlockedOnce), accessing.contains(.preventSync) {
            return .accessibleAfterFirstUnlockThisDeviceOnly
        }
        else if accessing.contains(.unlockedOnce) {
            return .accessibleAfterFirstUnlock
        }
        else if accessing.contains(.unlockedAtUse), accessing.contains(.preventSync) {
            return .accessibleWhenUnlockedThisDeviceOnly
        }
        else if accessing.contains(.unlockedAtUse) {
            return .accessibleWhenUnlocked
        }
        else if accessing.contains(.hasLock), accessing.contains(.preventSync) {
            return .accessibleWhenPasscodeSetThisDeviceOnly
        }
        else {
            assertionFailure("Cannot find the correct KeychainSwiftAccessOptions")
            return .accessibleAfterFirstUnlock
        }
    }
}
