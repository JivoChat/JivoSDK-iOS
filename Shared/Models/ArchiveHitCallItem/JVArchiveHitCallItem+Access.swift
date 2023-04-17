//
//  JVArchiveHitCallItem+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

public enum APICallType: String, APISelectableType {
    case none = "call.none"
    case incoming = "call.incoming"
    case outgoing = "call.outgoing"
    case callback = "call.callback"
    case missed = "call.missed"
    case failed = "call.failed"
    
    init?(codeValue: String) {
        switch codeValue {
        case "none": self = .none
        case "incoming": self = .incoming
        case "outgoing": self = .outgoing
        case "callbacks": self = .callback
        case "missed": self = .missed
        case "unsuccessful": self = .failed
        default: return nil
        }
    }
    
    public var publicCode: String {
        switch self {
            case .none: return "none"
            case .incoming: return "incoming"
            case .outgoing: return "outgoing"
            case .callback: return "callbacks"
            case .missed: return "missed"
            case .failed: return "unsuccessful"
        }
    }
    
    public var isNone: Bool {
        return (self == .none)
    }
    
    public static var allCases: [APICallType] {
        return [.incoming, .outgoing, .callback, .missed, .failed]
    }
}

extension JVArchiveHitCallItem {
    public var type: APICallType {
        if m_status == "unsuccessful" {
            return .failed
        }
        else if m_status == "missed" {
            return .missed
        }
        else {
            return APICallType(codeValue: m_type.jv_orEmpty) ?? .none
        }
    }
}
