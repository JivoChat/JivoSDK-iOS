//
//  Bundle+Extensions.swift
//  App
//
//  Created by Anton Karpushko on 03.03.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

extension Bundle {
    static func identifier(preset: IdentifierPreset) -> String {
        return preset.rawValue
    }
    
    static var jivoSdk: Bundle {
        if let sdkClass = objc_lookUpClass("Jivo") {
            return Bundle(for: sdkClass)
        }
        else {
            return .main
        }
    }
    
    static var auto: Bundle {
        #if ENV_APP
        print("Bundle::auto = main")
        return .main
        #else
        print("Bundle::auto = sdk")
        return .jivoSdk
        #endif
    }
}

extension Bundle {
    enum IdentifierPreset: String {
        case rmo = "com.jivosite.mobile"
        case sdk = "com.jivosite.jivosdk"
        case demo = "com.jivosite.jivosdkdemo"
    }
}
