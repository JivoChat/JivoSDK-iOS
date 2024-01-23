//
//  JVTopic.swift
//  App
//

import Foundation

@objc(JVTopic)
class JVTopic: JVDatabaseModel {
    override func apply(context: JVIDatabaseContext, change: JVDatabaseModelChange) {
        super.apply(context: context, change: change)
        performApply(context: context, environment: context.environment, change: change)
    }
}
