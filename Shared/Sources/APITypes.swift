//
//  APITypes.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 02/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

struct APILiveConnectionHandlers {
    let openHandler: () -> Void
    let closeHandler: (APIConnectionCloseCode, Error?) -> Void
    
    init(
        openHandler: @escaping () -> Void,
        closeHandler: @escaping (APIConnectionCloseCode, Error?) -> Void
    ) {
        self.openHandler = openHandler
        self.closeHandler = closeHandler
    }
}

enum APIAgentStatus {
    case present
    case away
}

enum APIAgentRelation: String {
    case invited = "invited"
    case attendee = "attendee"
}

enum APIConnectionCloseCode {
    case connectionBreak
    case sessionEnd
    case blacklist
    case deleted
    case sanctions
    case missingConnection
    case invalidConnection
    case invalidToken
    case unknown(Int)

    var description: String {
        switch self {
        case .connectionBreak: return "connection-break"
        case .sessionEnd: return "session-end"
        case .blacklist: return "blacklist"
        case .deleted: return "deleted"
        case .sanctions: return "sanctions"
        case .missingConnection: return "missing-connection"
        case .invalidToken: return "invalid-token"
        case .invalidConnection: return "invalid-connection"
        case .unknown(let code): return "unknown-\(code)"
        }
    }
}

enum APIConnectionLoginError {
    case badCredentials
    case sessionExpired
    case usersLimit
    case channelLimit
    case technicalError
    case maintenance
    case nodeRedirect(String)
    case moved
    case textual(String)
    case unknown
}

enum APIChatRemoveReason {
    case none
    case accepted(by: Int)
    case cancelled(by: Int)
}

struct APIEarlyChangeSet {
    let date: Date?
    let messageType: String
    let clientChange: JVClientShortChange?
    let agentChange: JVAgentShortChange?
    let chatChange: JVChatShortChange?
    let messageChange: JVMessageShortChange?
    
    init(
        date: Date?,
        messageType: String,
        clientChange: JVClientShortChange?,
        agentChange: JVAgentShortChange?,
        chatChange: JVChatShortChange?,
        messageChange: JVMessageShortChange?
    ) {
        self.date = date
        self.messageType = messageType
        self.clientChange = clientChange
        self.agentChange = agentChange
        self.chatChange = chatChange
        self.messageChange = messageChange
    }
}

struct APIAlreadyKeptSet {
    let agentChange: JVAgentShortChange
    let clientChange: JVClientShortChange
    let chatChange: JVChatShortChange
    let meID: Int
    
    init(
        agentChange: JVAgentShortChange,
        clientChange: JVClientShortChange,
        chatChange: JVChatShortChange,
        meID: Int
    ) {
        self.agentChange = agentChange
        self.clientChange = clientChange
        self.chatChange = chatChange
        self.meID = meID
    }
}

struct TelephonyCallInvite {
    let ID: String
    let direction: PhoneCallDirection?
    let webhookLink: String
    let token: String
    let clientID: Int
    let displayName: String
    let phone: String
    
    init(
        ID: String,
        direction: PhoneCallDirection?,
        webhookLink: String,
        token: String,
        clientID: Int,
        displayName: String,
        phone: String
    ) {
        self.ID = ID
        self.direction = direction
        self.webhookLink = webhookLink
        self.token = token
        self.clientID = clientID
        self.displayName = displayName
        self.phone = phone
    }
    
    static func parse(json: JsonElement) -> TelephonyCallInvite? {
        guard let callID = json["call_id"].string else { return nil }
        guard let webhookLink = json["webhook_url"].string else { return nil }
        guard let token = json["token"].string else { return nil }
        guard let phone = json["phone"].string else { return nil }
        guard let clientID = json["client_id"].int else { return nil }
        
        return TelephonyCallInvite(
            ID: callID,
            direction: .incoming,
            webhookLink: webhookLink,
            token: token,
            clientID: clientID,
            displayName: phone,
            phone: phone
        )
    }
    
    func copy(phone: String, displayName: String) -> TelephonyCallInvite {
        return TelephonyCallInvite(
            ID: ID,
            direction: direction,
            webhookLink: webhookLink,
            token: token,
            clientID: clientID,
            displayName: displayName,
            phone: phone
        )
    }
}

struct TelephonyCallReject {
    let callID: String
    let agentID: Int?
    
    init(callID: String, agentID: Int?) {
        self.callID = callID
        self.agentID = agentID
    }
    
    static func parse(json: JsonElement) -> TelephonyCallReject? {
        guard let callID = json["call_id"].string else { return nil }
        let agentID = json["agent_id"].int

        return TelephonyCallReject(
            callID: callID,
            agentID: agentID
        )
    }
}

enum APICallEvent {
    case invite(TelephonyCallInvite, () -> Void)
    case reject(TelephonyCallReject)
}

enum APITaskType: String, APISelectableType {
    case none = "reminder.none"
    case with = "reminder.with"
    case fired = "reminder.fired"
    case without = "reminder.without"
    case completed = "reminder.completed"
    
    init?(codeValue: String) {
        switch codeValue {
        case "none": self = .none
        case "with-reminders": self = .with
        case "fired-reminders": self = .fired
        case "without-reminders": self = .without
        case "completed-reminders": self = .completed
        default: return nil
        }
    }
    
    var publicCode: String {
        switch self {
        case .none: return "none"
        case .with: return "with-reminders"
        case .fired: return "fired-reminders"
        case .without: return "without-reminders"
        case .completed: return "completed-reminders"
        }
    }
    
    var isNone: Bool {
        return (self == .none)
    }
    
    static var allCases: [APITaskType] {
        return [.with, .fired, .without, .completed]
    }
}

enum ApiChatStatus: String {
    case opened = "open"
    case closed = "closed"
}

struct APIAccount {
    let siteID: Int
    let channelID: Int
    let agentID: Int
    
    init(siteID: Int, channelID: Int, agentID: Int) {
        self.siteID = siteID
        self.channelID = channelID
        self.agentID = agentID
    }
}

struct TelephonyBalance {
    let amount: Double
    let currency: String
    
    init(amount: Double, currency: String) {
        self.amount = amount
        self.currency = currency
    }
}

struct TelephonyPhone {
    let ID: Int
    let active: Bool
    let number: String
    let countryCode: String
    let channelID: Int
    let type: String
    let status: String
    let price: Float
    let nextRenewalDate: String
    let isSmsSupported: Bool
    let purchasePrice: Float
    let ivrAvailable: Bool
    let sipURI: String?
    let autoChange: Bool?
    let sipStatus: String?
}

struct TelephonyConfig {
    let voxNode: String?
    let phones: [TelephonyPhone]
    let balance: TelephonyBalance?
}
