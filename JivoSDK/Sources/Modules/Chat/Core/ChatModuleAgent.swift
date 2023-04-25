//
//  ChatAgent.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 15.10.2021.
//

import Foundation
import JivoFoundation

struct ChatModuleAgent {
    let id: Int
    let name: String
    let avatarLink: String
    let status: Status
}

extension ChatModuleAgent {
    enum Status {
        case active
        case away
        case custom(String)
    }
}

extension ChatModuleAgent.Status {
    init(agentState: JVAgentState) {
        switch agentState {
        case .active: self = .active
        case .away: self = .away
        case .none: self = .custom("none")
        }
    }
}

extension ChatModuleAgent.Status: Equatable {}
