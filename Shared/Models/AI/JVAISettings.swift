//
//  JVAISettings.swift
//  App
//
//  Created by Julia Popova on 31.01.2024.
//

import Foundation
import JMCodingKit

final class JVAISettings: JVDatabaseModelChange {
    let siteId: Int
    let enableAiModule: Bool
    let enableAiAssistant: Bool
    let enableAiCopilot: Bool
    let enableAiSummarize: Bool
    let createdTs: Int
    let updatedTs: Int
    
    required init(json: JsonElement) {
        siteId = json["site_id"].intValue
        enableAiModule = json["enable_ai_module"].boolValue
        enableAiAssistant = json["enable_ai_assistant"].boolValue
        enableAiCopilot = json["enable_ai_copilot"].boolValue
        enableAiSummarize = json["enable_ai_summarize"].boolValue
        createdTs = json["created_ts"].intValue
        updatedTs = json["updated_ts"].intValue
        super.init(json: json)
    }
}
