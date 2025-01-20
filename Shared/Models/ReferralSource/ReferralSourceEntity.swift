//
//  ReferralSourceEntity.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 30.10.2024.
//

import Foundation

@objc(ReferralSourceEntity)
class ReferralSourceEntity: DatabaseEntity {
    override func apply(context: JVIDatabaseContext, change: JVDatabaseModelChange) {
        super.apply(context: context, change: change)
        performApply(context: context, environment: context.environment, change: change)
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
    }
}
