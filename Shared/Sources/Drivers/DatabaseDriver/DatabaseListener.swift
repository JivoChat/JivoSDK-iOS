//
//  DatabaseListener.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 15/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation

public final class JVDatabaseListener {
    private let token: JVDatabaseDriverSubscriberToken
    private weak var coreDataDriver: JVIDatabaseDriver!
    
    init(token: JVDatabaseDriverSubscriberToken, coreDataDriver: JVIDatabaseDriver) {
        self.token = token
        self.coreDataDriver = coreDataDriver
    }
    
    deinit {
        coreDataDriver?.unsubscribe(token)
    }
}
