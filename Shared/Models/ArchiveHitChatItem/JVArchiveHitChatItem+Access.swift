//
//  JVArchiveHitChatItem+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

public protocol APISelectableType {
    var publicCode: String { get }
    var isNone: Bool { get }
}

public enum APIChatType: String, APISelectableType {
    case none = "chat.none"
    case incoming = "chat.incoming"
    case outgoing = "chat.outgoing"
    case missed = "chat.missed"
    case blocked = "chat.blocked"
    
    init?(codeValue: String) {
        switch codeValue {
        case "none": self = .none
        case "incoming": self = .incoming
        case "outgoing": self = .outgoing
        case "missed": self = .missed
        case "banned": self = .blocked
        default: return nil
        }
    }
    
    public var publicCode: String {
        switch self {
        case .none: return "none"
        case .incoming: return "incoming"
        case .outgoing: return "outgoing"
        case .missed: return "missed"
        case .blocked: return "banned"
        }
    }
    
    public var isNone: Bool {
        return (self == .none)
    }
    
    public static var allCases: [APIChatType] {
        return [.incoming, .outgoing, .missed, .blocked]
    }
}

extension JVArchiveHitChatItem {
    public var type: APIChatType {
        return APIChatType(codeValue: m_type.jv_orEmpty) ?? .none
    }
}
