//
//  ApnsConnectionDriver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 22/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

final class ApnsConnectionDriver: IApnsConnectionDriver {
    var messageHandler: ((JsonElement, UIApplication.State, Date?) -> Void)?
    
    init() {
    }
}
