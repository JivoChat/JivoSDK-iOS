//
//  SdkChatContext.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 24.03.2022.
//

import Foundation


protocol ISdkChatContext: AnyObject {
    var chatRef: DatabaseEntityRef<ChatEntity>? { get set }
    var chatAgents: [Int: DatabaseEntityRef<AgentEntity>] { get set }
    var channelAgents: [Int: DatabaseEntityRef<AgentEntity>] { get set }
}

final class SdkChatContext: ISdkChatContext {
    var chatRef: DatabaseEntityRef<ChatEntity>?
    var chatAgents = [Int: DatabaseEntityRef<AgentEntity>]()
    var channelAgents = [Int: DatabaseEntityRef<AgentEntity>]()
}
