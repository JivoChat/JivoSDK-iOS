//
//  SecureJson.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 21.12.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

var sharedSecureJsonProxy: JsonPrivacyTool?
    
func secureJson(_ json: JsonElement) -> JsonElement {
    return sharedSecureJsonProxy?.filter(json: json) ?? json
}
