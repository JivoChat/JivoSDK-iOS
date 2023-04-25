//
//  BaseChattingSubStorage.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 03.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation


protocol IBaseChattingSubStorage: ICommonSubStorage {
}

class BaseChattingSubStorage: CommonSubStorage, IBaseChattingSubStorage {
    let systemMessagingService: ISystemMessagingService
    
    init(userContext: AnyObject, databaseDriver: JVIDatabaseDriver, systemMessagingService: ISystemMessagingService) {
        self.systemMessagingService = systemMessagingService
        
        super.init(
            userContext: userContext,
            databaseDriver: databaseDriver)
    }
}
