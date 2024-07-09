//
//  AiCopilotSkillEntity.swift
//  App
//
//  Created by Julia Popova on 06.02.2024.
//

import Foundation

@objc(AiCopilotSkillEntity)
class AiCopilotSkillEntity: DatabaseEntity {
    override func apply(context: JVIDatabaseContext, change: JVDatabaseModelChange) {
        super.apply(context: context, change: change)
        performApply(context: context, environment: context.environment, change: change)
    }
}
