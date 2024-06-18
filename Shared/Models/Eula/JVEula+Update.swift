//
//  JVEula+Update.swift
//  App
//
//  Created by Yulia Popova on 29.06.2023.
//

import Foundation
import JMCodingKit

extension JVEula {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let change = change as? JVEulaGeneralChange {
            m_module = change.module
            m_agent_id = Int32(change.agentID)
        }
    }
}

final class JVEulaGeneralChange: JVDatabaseModelChange, Codable {
    let module: String
    let agentID: Int
    
    override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_module", value: module)
    }
    
    public required init(json: JsonElement) {
        module = json["module"].stringValue
        agentID = json["agent_id"].intValue
        super.init(json: json)
    }

    init(
        module: String,
        agentID: Int
    ) {
        self.module = module
        self.agentID = agentID
        super.init()
    }
}
