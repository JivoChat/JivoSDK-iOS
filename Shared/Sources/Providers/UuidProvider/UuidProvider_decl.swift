//
//  UUIDProvider.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 09/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

protocol IUUIDProvider: AnyObject {
    var currentDeviceID: String { get }
    var currentInstallationID: String { get }
    var currentLaunchID: String { get }
    var userAgentBrief: String { get }
}
