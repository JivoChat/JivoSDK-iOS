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
    case missingConnection
    case invalidConnection
    case invalidToken
    case unknown(Int)

    var description: String {
        switch self {
        case .connectionBreak: return "connection-break"
        case .sessionEnd: return "session-end"
        case .blacklist: return "blacklisted"
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

struct APICallInvite {
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
    
    static func parse(json: JsonElement) -> APICallInvite? {
        guard let callID = json["call_id"].string else { return nil }
        guard let webhookLink = json["webhook_url"].string else { return nil }
        guard let token = json["token"].string else { return nil }
        guard let phone = json["phone"].string else { return nil }
        guard let clientID = json["client_id"].int else { return nil }
        
        return APICallInvite(
            ID: callID,
            direction: .incoming,
            webhookLink: webhookLink,
            token: token,
            clientID: clientID,
            displayName: phone,
            phone: phone
        )
    }
    
    func copy(phone: String, displayName: String) -> APICallInvite {
        return APICallInvite(
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

struct APICallReject {
    let callID: String
    let agentID: Int?
    
    init(callID: String, agentID: Int?) {
        self.callID = callID
        self.agentID = agentID
    }
    
    static func parse(json: JsonElement) -> APICallReject? {
        guard let callID = json["call_id"].string else { return nil }
        let agentID = json["agent_id"].int

        return APICallReject(
            callID: callID,
            agentID: agentID
        )
    }
}

enum APICallEvent {
    case invite(APICallInvite, () -> Void)
    case reject(APICallReject)
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

struct APIBalance {
    let amount: Double
    let currency: String
    
    init(amount: Double, currency: String) {
        self.amount = amount
        self.currency = currency
    }
}

struct APIPhone {
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
    
    init(
        ID: Int,
        active: Bool,
        number: String,
        countryCode: String,
        channelID: Int,
        type: String,
        status: String,
        price: Float,
        nextRenewalDate: String,
        isSmsSupported: Bool,
        purchasePrice: Float,
        ivrAvailable: Bool,
        sipURI: String?,
        autoChange: Bool?,
        sipStatus: String?
    ) {
            self.ID = ID
            self.active = active
            self.number = number
            self.countryCode = countryCode
            self.channelID = channelID
            self.type = type
            self.status = status
            self.price = price
            self.nextRenewalDate = nextRenewalDate
            self.isSmsSupported = isSmsSupported
            self.purchasePrice = purchasePrice
            self.ivrAvailable = ivrAvailable
            self.sipURI = sipURI
            self.autoChange = autoChange
            self.sipStatus = sipStatus
        }
}

struct APITelephony {
    let phones: [APIPhone]
    let balance: APIBalance?
    
    init(phones: [APIPhone], balance: APIBalance?) {
        self.phones = phones
        self.balance = balance
    }
}

struct APIPromo {
    let demoDuration: Int?
    let callsCount: Int?
    let minutesCount: Int?
    let agentsCount: Int?

    init(json: JsonElement) {
        demoDuration = json["demo_duration"].int
        callsCount = json["calls_count"].int
        minutesCount = json["minutes_count"].int
        agentsCount = json["agents"].int
    }
}
