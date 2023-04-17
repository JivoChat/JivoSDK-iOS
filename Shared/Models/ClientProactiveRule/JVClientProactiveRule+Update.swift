//
//  JVClientProactiveRule+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVClientProactiveRule {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let c = change as? JVClientProactiveRuleGeneralChange {
            m_agent = context.agent(for: c.agentID, provideDefault: true)
            m_date = c.date
            m_text = c.text
        }
    }
}

public final class JVClientProactiveRuleGeneralChange: JVDatabaseModelChange {
    public let agentID: Int
    public let date: Date
    public let text: String
    
    required public init(json: JsonElement) {
        agentID = json["agent_id"].intValue
        date = json["time"].string?.jv_parseDateUsingFullFormat() ?? Date(timeIntervalSince1970: 0)
        text = json["invitation_text"].stringValue
        super.init(json: json)
    }
}
