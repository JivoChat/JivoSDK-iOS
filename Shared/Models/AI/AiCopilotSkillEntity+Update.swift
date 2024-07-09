//
//  AiCopilotSkillEntity+Update.swift
//  App
//
//  Created by Julia Popova on 06.02.2024.
//

import Foundation
import JMCodingKit

extension AiCopilotSkillEntity {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = Int64(m_id)
        }
        
        if let c = change as? JVAICopilotSkillsChange {
            m_id = Int16(c.skillID)
            m_title = c.skillName
            m_emoji = c.emoji
        }
    }
}

final class JVAICopilotSkillsChange: JVDatabaseModelChange {
    public let skillID: Int
    public let skillName: String
    public let emoji: String

    override var primaryValue: Int {
        return skillID
    }
    
    override var isValid: Bool {
        return (skillID > 0)
    }
    
    required init(json: JsonElement) {
        skillID = json["ai_copilot_skill_settings_id"].intValue
        skillName = json["title"].stringValue
        emoji = json["emoji"].stringValue
        super.init(json: json)
    }
}
