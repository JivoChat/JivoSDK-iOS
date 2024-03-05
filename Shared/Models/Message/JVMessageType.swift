//
//  JVMessageType.swift
//  App
//
//  Created by Stan Potemkin on 31.01.2024.
//

import Foundation

extension JVMessageType {
    static let message = Predefined.message
    static let email = Predefined.email
    static let invite = Predefined.invite
    static let transfer = Predefined.transfer
    static let join = Predefined.join
    static let left = Predefined.left
    static let call = Predefined.call
    static let line = Predefined.line
    static let reminder = Predefined.reminder
    static let reminderUpdate = Predefined.reminder_update
    static let comment = Predefined.comment
    static let keyboard = Predefined.keyboard
    static let order = Predefined.order
    static let system = Predefined.system
    static let proactive = Predefined.proactive
    static let offline = Predefined.offline
    static let hello = Predefined.hello
    static let contactForm = Predefined.contact_form
    static let chatRate = Predefined.chat_rate
    static let unknown = Predefined.unknown
}

struct JVMessageType: Equatable {
    let name: Name
    let belonging: Belonging
    
    init(name: Name, belonging: Belonging, collectInto allRef: inout [String: Self]) {
        self.name = name
        self.belonging = belonging
        
        allRef[name.exportable()] = self
    }
    
    func exportableName() -> String {
        return name.exportable()
    }
}

extension JVMessageType {
    enum Name: Equatable {
        case proto(String)
        case custom(String)
    }
    
    enum Belonging {
        case shown
        case smart
        case hidden
    }
}

extension JVMessageType {
    static func by(name: String) -> Self? {
        if let value = Predefined.types[Name.proto(name).exportable()] {
            return value
        }
        
        let customBase = name.replacingOccurrences(of: Name.customPrefix, with: String())
        if let value = Predefined.types[Name.custom(customBase).exportable()] {
            return value
        }
        else if let value = Predefined.types[Name.proto(customBase).exportable()] {
            // SP: Migration from the old style to the new one
            return value
        }

        return Predefined.types[name]
    }
}

extension JVMessageType.Name {
    static let customPrefix = "custom:"
    
    func exportable() -> String {
        switch self {
        case .proto(let value):
            return value
        case .custom(let value):
            return Self.customPrefix + value
        }
    }
}

fileprivate let Predefined = _Predefined()
fileprivate struct _Predefined {
    static private var types = [String: JVMessageType]()
    var types: [String: JVMessageType] { Self.types }
    
    let message = JVMessageType(
        name: .proto("message"),
        belonging: .shown,
        collectInto: &types)

    let email = JVMessageType(
        name: .proto("email"),
        belonging: .shown,
        collectInto: &types)

    let invite = JVMessageType(
        name: .proto("invite"),
        belonging: .hidden,
        collectInto: &types)

    let transfer = JVMessageType(
        name: .proto("transfer"),
        belonging: .hidden,
        collectInto: &types)

    let join = JVMessageType(
        name: .proto("join"),
        belonging: .hidden,
        collectInto: &types)

    let left = JVMessageType(
        name: .proto("left"),
        belonging: .hidden,
        collectInto: &types)

    let call = JVMessageType(
        name: .proto("call"),
        belonging: .smart,
        collectInto: &types)

    let line = JVMessageType(
        name: .proto("line"),
        belonging: .hidden,
        collectInto: &types)

    let reminder = JVMessageType(
        name: .proto("reminder"),
        belonging: .hidden,
        collectInto: &types)

    let reminder_update = JVMessageType(
        name: .proto("reminder_update"),
        belonging: .hidden,
        collectInto: &types)

    let comment = JVMessageType(
        name: .proto("comment"),
        belonging: .shown,
        collectInto: &types)

    let keyboard = JVMessageType(
        name: .proto("keyboard"),
        belonging: .shown,
        collectInto: &types)

    let order = JVMessageType(
        name: .proto("order"),
        belonging: .shown,
        collectInto: &types)

    let system = JVMessageType(
        name: .proto("system"),
        belonging: .hidden,
        collectInto: &types)

    let proactive = JVMessageType(
        name: .proto("proactive"),
        belonging: .shown,
        collectInto: &types)

    let offline = JVMessageType(
        name: .custom("offline"),
        belonging: .shown,
        collectInto: &types)

    let hello = JVMessageType(
        name: .custom("hello"),
        belonging: .shown,
        collectInto: &types)

    let contact_form = JVMessageType(
        name: .custom("contact_form"),
        belonging: .hidden,
        collectInto: &types)

    let chat_rate = JVMessageType(
        name: .custom("chat_rate"),
        belonging: .hidden,
        collectInto: &types)

    let unknown = JVMessageType(
        name: .custom("unknown"),
        belonging: .shown,
        collectInto: &types)
}
