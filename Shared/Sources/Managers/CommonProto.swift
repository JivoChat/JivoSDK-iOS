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
    let agentRef: DatabaseEntityRef<AgentEntity>
    
    init(agentRef: DatabaseEntityRef<AgentEntity>) {
        self.agentRef = agentRef
    }
}

struct APISendMessageContext {
    let chatID: Int
    let outmessageRef: DatabaseEntityRef<MessageEntity>
    
    init(chatID: Int, outmessageRef: DatabaseEntityRef<MessageEntity>) {
        self.chatID = chatID
        self.outmessageRef = outmessageRef
    }
}

struct APISendMediaContext {
    let outmessageRef: DatabaseEntityRef<MessageEntity>
    
    init(outmessageRef: DatabaseEntityRef<MessageEntity>) {
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
