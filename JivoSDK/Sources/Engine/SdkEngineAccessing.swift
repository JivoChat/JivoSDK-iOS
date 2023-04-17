//
//  SdkEngineAccessing.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

protocol SdkEngineAccessing {
    var engine: ISdkEngine { get }
}

extension SdkEngineAccessing {
    var engine: ISdkEngine {
        return SdkEngine.shared
    }
}
