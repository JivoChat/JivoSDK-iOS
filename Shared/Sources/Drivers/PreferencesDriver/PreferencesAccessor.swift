//
//  PreferencesAccessor.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation

protocol IPreferencesAccessor: AnyObject {
    var key: String { get }
    var hasObject: Bool { get }
    var object: Any? { get set }
    var string: String? { get set }
    var stringCollection: [String] { get set }
    var boolean: Bool { get set }
    var number: Int { get set }
    var date: Date? { get set }
    var data: Data? { get set }
    var locale: Locale { get set }
    func erase()
}

final class PreferencesAccessor: IPreferencesAccessor {
    let storage: UserDefaults
    let key: String
    
    init(storage: UserDefaults, key: String) {
        self.storage = storage
        self.key = key
    }
    
    var hasObject: Bool {
        return !(object == nil)
    }
    
    var object: Any? {
        get { storage.object(forKey: key) }
        set { storage.set(newValue, forKey: key) }
    }
    
    var string: String? {
        get { storage.string(forKey: key) }
        set { storage.set(newValue, forKey: key) }
    }
    
    var stringCollection: [String] {
        get { storage.stringArray(forKey: key) ?? [] }
        set { storage.set(newValue, forKey: key) }
    }
    
    var boolean: Bool {
        get { storage.bool(forKey: key) }
        set { storage.set(newValue, forKey: key) }
    }
    
    var number: Int {
        get { storage.integer(forKey: key) }
        set { storage.set(newValue, forKey: key) }
    }
    
    var date: Date? {
        get { storage.object(forKey: key) as? Date }
        set { storage.set(newValue, forKey: key) }
    }
    
    var data: Data? {
        get { storage.object(forKey: key) as? Data }
        set { storage.set(newValue, forKey: key) }
    }
    
    var locale: Locale {
        get { storage.string(forKey: key).map(Locale.init) ?? .current }
        set { storage.set(newValue.identifier, forKey: key) }
    }
    
    func erase() {
        storage.removeObject(forKey: key)
    }
}
