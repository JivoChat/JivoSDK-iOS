//
//  JVPushCredentials.swift
//  App
//
//  Created by Stan Potemkin on 04.02.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

@objc(JVPushCredentials)
class JVPushCredentials: JVDatabaseModel {
    override func apply(context: JVIDatabaseContext, change: JVDatabaseModelChange) {
        super.apply(context: context, change: change)
        performApply(context: context, environment: context.environment, change: change)
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        m_date = Date()
        m_status = Status.waitingForRegister.rawValue
    }
}
