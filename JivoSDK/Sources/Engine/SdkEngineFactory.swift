//
//  SdkEngineFactory.swift
//  JivoSDK
//

import Foundation
import KeychainSwift

struct SdkEngineFactory {
    static func build() -> ISdkEngine {
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        
        return SdkEngine(
            namespace: "jivosdk",
            userDefaults: .standard,
            keychain: keychain,
            fileManager: .default,
            urlSession: .shared,
            schedulingCore: SdkSchedulingCore()
        )
    }
}
