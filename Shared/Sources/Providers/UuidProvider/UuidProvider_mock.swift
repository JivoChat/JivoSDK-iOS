//
//  UuidProviderMock.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
@testable import Jivo

class UUIDProviderMock: IUUIDProvider {
    var currentDeviceID: String {
        fatalError()
    }
    
    var currentInstallationID: String {
        fatalError()
    }
    
    var currentLaunchID: String {
        fatalError()
    }
    
    var userAgentBrief: String {
        fatalError()
    }
}
