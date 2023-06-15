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

class JVDatabaseModelChange: NSObject {
    public let isOK: Bool
    
    override init() {
        isOK = true

        super.init()
    }
    
    required init(json: JsonElement) {
        isOK = json["ok"].boolValue
    }
    
    var isValid: Bool {
        return true
    }
    
    var primaryValue: Int {
        abort()
    }
    
    var integerKey: JVDatabaseModelCustomId<Int>? {
        return nil
    }
    
    var stringKey: JVDatabaseModelCustomId<String>? {
        return nil
    }
}

func JVValidChange<T: JVDatabaseModelChange>(_ change: T?) -> T? {
    if let change = change, change.isValid {
        return change
    }
    else {
        return nil
    }
}

enum JVSenderType: String {
    case `self`
    case client = "client"
    case agent = "agent"
    case bot = "bot"
    case guest = "visitor"
    case teamchat = "teamchat"
    case department = "department"
}

struct JVSenderData: Equatable {
    let type: JVSenderType
    let ID: Int
}

enum JVDisplayNameKind {
    case original
    case short
    case decorative(Decor)
    case relative
}

extension JVDisplayNameKind {
    struct Decor: OptionSet {
        let rawValue: Int
        static let role = Self(rawValue: 1 << 0)
        static let status = Self(rawValue: 1 << 1)
        static let all = Self(rawValue: ~0)
    }
}
