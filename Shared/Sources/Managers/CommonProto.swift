//
//  CommonProto.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

struct APIChatDetailsContext {
    let chatID: Int
    
    init(chatID: Int) {
        self.chatID = chatID
    }
}

struct APIChatRequestContext {
    let agentRef: JVDatabaseModelRef<JVAgent>
    
    init(agentRef: JVDatabaseModelRef<JVAgent>) {
        self.agentRef = agentRef
    }
}

struct APISendMessageContext {
    let chatID: Int
    let outmessageRef: JVDatabaseModelRef<JVMessage>
    
    init(chatID: Int, outmessageRef: JVDatabaseModelRef<JVMessage>) {
        self.chatID = chatID
        self.outmessageRef = outmessageRef
    }
}

struct APISendMediaContext {
    let outmessageRef: JVDatabaseModelRef<JVMessage>
    
    init(outmessageRef: JVDatabaseModelRef<JVMessage>) {
        self.outmessageRef = outmessageRef
    }
}

enum APILogoutReason {
    case regularRequest
    case anotherDevice
    case agentDeletion
    case maintenance
}

enum APIRequestCommand {
    case operatingRevoked
    case statusListUpdate([JVAgentStatusGeneralChange])
    case unknown
}

enum APIRequestNotification {
    case navigateWeb(URL)
    case uploadJournal
    case updateFeatures
}
