//
//  JVPushCredentials.swift
//  App
//
//  Created by Stan Potemkin on 04.02.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

@objc(JVPushCredentials)
public class JVPushCredentials: JVDatabaseModel {
    public override func apply(context: JVIDatabaseContext, change: JVDatabaseModelChange) {
        super.apply(context: context, change: change)
        performApply(context: context, environment: context.environment, change: change)
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        m_date = Date()
        m_status = Status.waitingForRegister.rawValue
    }
}
