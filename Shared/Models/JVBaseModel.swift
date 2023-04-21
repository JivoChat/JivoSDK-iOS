//
//  JVBaseModel.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 12/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit
import JMRepicKit

open class JVDatabaseModelChange: NSObject {
    public let isOK: Bool
    
    override public init() {
        isOK = true

        super.init()
    }
    
    required public init(json: JsonElement) {
        isOK = json["ok"].boolValue
    }
    
    open var isValid: Bool {
        return true
    }
    
    open var primaryValue: Int {
        abort()
    }
    
    open var integerKey: JVDatabaseModelCustomId<Int>? {
        return nil
    }
    
    open var stringKey: JVDatabaseModelCustomId<String>? {
        return nil
    }
}

public func JVValidChange<T: JVDatabaseModelChange>(_ change: T?) -> T? {
    if let change = change, change.isValid {
        return change
    }
    else {
        return nil
    }
}

public enum JVSenderType: String {
    case `self`
    case client = "client"
    case agent = "agent"
    case bot = "bot"
    case guest = "visitor"
    case teamchat = "teamchat"
    case department = "department"
}

public struct JVSenderData: Equatable {
    public let type: JVSenderType
    public let ID: Int
    
    public init(type: JVSenderType, ID: Int) {
        self.type = type
        self.ID = ID
    }
}

public enum JVDisplayNameKind {
    case original
    case short
    case decorative(Decor)
    case relative
}

extension JVDisplayNameKind {
    public struct Decor: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        
        public static let role = Self(rawValue: 1 << 0)
        public static let status = Self(rawValue: 1 << 1)
        public static let all = Self(rawValue: ~0)
    }
}
