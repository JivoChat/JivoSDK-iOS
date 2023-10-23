//
//  JVEula.swift
//  App
//
//  Created by Yulia Popova on 29.06.2023.
//

import Foundation

@objc(JVEula)
class JVEula: JVDatabaseModel {
    override func apply(context: JVIDatabaseContext, change: JVDatabaseModelChange) {
        super.apply(context: context, change: change)
        performApply(context: context, environment: context.environment, change: change)
    }
}
