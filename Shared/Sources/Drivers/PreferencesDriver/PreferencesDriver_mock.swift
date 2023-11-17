//
//  PreferencesDriver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 02/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
@testable import App

class PreferencesDriverMock: IPreferencesDriver {
    let signal = JVBroadcastTool<Void>()
    
    init() {
    }
    
    func migrate(keys: [String]) {
        fatalError()
    }
    
    func register(defaults: [String: Any]) {
        fatalError()
    }

    final func detectFirstLaunch() -> Bool {
        fatalError()
    }
    
    final func retrieveAccessor(forToken token: PreferencesToken) -> IPreferencesAccessor {
        fatalError()
    }
    
    func clearAll() {
        fatalError()
    }
}
