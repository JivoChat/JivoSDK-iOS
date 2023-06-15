//
//  SdkChatContext.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 24.03.2022.
//

import Foundation


protocol ISdkChatContext: AnyObject {
    var chatRef: JVDatabaseModelRef<JVChat>? { get set }
    var chatAgents: [Int: JVDatabaseModelRef<JVAgent>] { get set }
    var channelAgents: [Int: JVDatabaseModelRef<JVAgent>] { get set }
}

final class SdkChatContext: ISdkChatContext {
    var chatRef: JVDatabaseModelRef<JVChat>?
    var chatAgents = [Int: JVDatabaseModelRef<JVAgent>]()
    var channelAgents = [Int: JVDatabaseModelRef<JVAgent>]()
}
