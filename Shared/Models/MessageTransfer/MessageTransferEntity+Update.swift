//
//  MessageTransferEntity+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension MessageTransferEntity {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let c = change as? JVMessageTransferGeneralChange {
            m_agent_id = c.agentID.jv_toInt64(.standard)
            m_comment = c.comment
        }
    }
}

final class JVMessageTransferGeneralChange: JVDatabaseModelChange {
    public let agentID: Int
    public let comment: String?
    
    required init(json: JsonElement) {
        agentID = json["agent_id"].intValue
        comment = json["text"].valuable
        super.init(json: json)
    }
}
