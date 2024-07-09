//
//  MessageType.swift
//  App
//
//  Created by Stan Potemkin on 31.01.2024.
//

import Foundation

extension MessageType {
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

struct MessageType: Equatable {
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

extension MessageType {
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

extension MessageType {
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

extension MessageType.Name {
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
    static private var types = [String: MessageType]()
    var types: [String: MessageType] { Self.types }
    
    let message = MessageType(
        name: .proto("message"),
        belonging: .shown,
        collectInto: &types)

    let email = MessageType(
        name: .proto("email"),
        belonging: .shown,
        collectInto: &types)

    let invite = MessageType(
        name: .proto("invite"),
        belonging: .hidden,
        collectInto: &types)

    let transfer = MessageType(
        name: .proto("transfer"),
        belonging: .hidden,
        collectInto: &types)

    let join = MessageType(
        name: .proto("join"),
        belonging: .hidden,
        collectInto: &types)

    let left = MessageType(
        name: .proto("left"),
        belonging: .hidden,
        collectInto: &types)

    let call = MessageType(
        name: .proto("call"),
        belonging: .smart,
        collectInto: &types)

    let line = MessageType(
        name: .proto("line"),
        belonging: .hidden,
        collectInto: &types)

    let reminder = MessageType(
        name: .proto("reminder"),
        belonging: .hidden,
        collectInto: &types)

    let reminder_update = MessageType(
        name: .proto("reminder_update"),
        belonging: .hidden,
        collectInto: &types)

    let comment = MessageType(
        name: .proto("comment"),
        belonging: .shown,
        collectInto: &types)

    let keyboard = MessageType(
        name: .proto("keyboard"),
        belonging: .shown,
        collectInto: &types)

    let order = MessageType(
        name: .proto("order"),
        belonging: .shown,
        collectInto: &types)

    let system = MessageType(
        name: .proto("system"),
        belonging: .hidden,
        collectInto: &types)

    let proactive = MessageType(
        name: .proto("proactive"),
        belonging: .shown,
        collectInto: &types)

    let offline = MessageType(
        name: .custom("offline"),
        belonging: .shown,
        collectInto: &types)

    let hello = MessageType(
        name: .custom("hello"),
        belonging: .shown,
        collectInto: &types)

    let contact_form = MessageType(
        name: .custom("contact_form"),
        belonging: .hidden,
        collectInto: &types)

    let chat_rate = MessageType(
        name: .custom("chat_rate"),
        belonging: .hidden,
        collectInto: &types)

    let unknown = MessageType(
        name: .custom("unknown"),
        belonging: .shown,
        collectInto: &types)
}
