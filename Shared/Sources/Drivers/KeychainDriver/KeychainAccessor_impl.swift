//
//  KeychainAccessor.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 18.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import KeychainSwift

class KeychainAccessor: IKeychainAccessor {
    private let storage: KeychainSwift
    private let namespace: String?
    private let scope: String?
    private let key: String
    private let options: KeychainSwiftAccessOptions
    
    private let dateFormatter = DateFormatter()
    
    init(storage: KeychainSwift, namespace: String?, scope: String?, key: String, options: KeychainSwiftAccessOptions) {
        self.storage = storage
        self.namespace = namespace
        self.scope = scope
        self.key = key
        self.options = options
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    }
    
    var hasObject: Bool {
        return !(storage.getData(path) == nil)
    }
    
    var string: String? {
        get {
            storage.get(path)
        }
        set {
            guard let value = newValue else { return erase() }
            storage.set(value, forKey: path, withAccess: options)
        }
    }
    
    var number: Int? {
        get {
            storage.get(path)?.jv_toInt()
        }
        set {
            guard let value = newValue else { return erase() }
            storage.set("\(value)", forKey: path, withAccess: options)
        }
    }
    
    var date: Date? {
        get {
            guard let value = storage.get(path) else { return nil }
            return dateFormatter.date(from: value)
        }
        set {
            guard let value = newValue.flatMap(dateFormatter.string) else { return erase() }
            storage.set(value, forKey: path, withAccess: options)
        }
    }
    
    var data: Data? {
        get {
            return storage.getData(path)
        }
        set {
            guard let value = newValue else { return erase() }
            storage.set(value, forKey: path, withAccess: options)
        }
    }
    
    func withScope(_ scope: String?) -> IKeychainAccessor {
        return KeychainAccessor(storage: storage, namespace: namespace, scope: scope, key: key, options: options)
    }
    
    func erase() {
        storage.delete(path)
    }
    
    private var path: String {
        let parts: [String?] = [namespace, scope, key]
        return parts.compactMap({$0}).joined(separator: ":")
    }
}
