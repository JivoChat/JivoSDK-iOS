//
//  WaTemplateEntity.swift
//  App
//
//  Created by Julia Popova on 04.04.2024.
//

import Foundation
import JMCodingKit

@objc(WaTemplateEntity)
class WaTemplateEntity: DatabaseEntity {
    override func apply(context: JVIDatabaseContext, change: JVDatabaseModelChange) {
        super.apply(context: context, change: change)
        performApply(context: context, environment: context.environment, change: change)
    }
}
