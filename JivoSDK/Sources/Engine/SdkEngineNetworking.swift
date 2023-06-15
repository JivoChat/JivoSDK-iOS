//
//  SdkEngineNetworking.swift
//  JivoSDK
//

import Foundation


protocol ISdkEngineNetworkingFactory {
    func build() -> INetworking
}

struct SdkEngineNetworkingFactory: ISdkEngineNetworkingFactory {
    let workerThread: JVIDispatchThread
    let networkingHelper: INetworkingHelper
    let socketDriver: ILiveConnectionDriver
    let restConnectionDriver: IRestConnectionDriver
    let localeProvider: JVILocaleProvider
    let uuidProvider: IUUIDProvider
    let preferencesDriver: IPreferencesDriver
    let keychainDriver: IKeychainDriver
    let jsonPrivacyTool: JVJsonPrivacyTool
    let hostProvider: (URL, String) -> URL?
    
    func build() -> INetworking {
        let networkSubSocket = NetworkingSubSocket(
            namespace: "jivosdk",
            identifier: UUID(),
            driver: socketDriver,
            networkingThread: workerThread,
            behavior: .json,
            jsonPrivacyTool: jsonPrivacyTool
        )
        
        let networkSubRest = NetworkingSubRest(
            networkingHelper: networkingHelper,
            driver: restConnectionDriver
        )
        
        return Networking(
            subSocket: networkSubSocket,
            subRest: networkSubRest,
            subApns: nil,
            localeProvider: localeProvider,
            uuidProvider: uuidProvider,
            preferencesDriver: preferencesDriver,
            keychainDriver: keychainDriver,
            jsonPrivacyTool: jsonPrivacyTool,
            hostProvider: hostProvider
        )
    }
}
