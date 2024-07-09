//
//  TopicEntity.swift
//  App
//

import Foundation

@objc(TopicEntity)
class TopicEntity: DatabaseEntity {
    override func apply(context: JVIDatabaseContext, change: JVDatabaseModelChange) {
        super.apply(context: context, change: change)
        performApply(context: context, environment: context.environment, change: change)
    }
}
