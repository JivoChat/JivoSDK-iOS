//
//  UuidSubUserAgentGenerator_decl.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 24.04.2023.
//

import Foundation

protocol IUuidSubUserAgentGenerator: AnyObject {
    func generate() -> String
}

enum UuidSubUserAgentPackage {
    case app
    case sdk
}
