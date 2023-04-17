//
//  SdkEngineNetworking.swift
//  JivoSDK
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif


protocol ISdkEngineNetworkingFactory {
    func build() -> INetworking
}

struct SdkEngineNetworkingFactory: ISdkEngineNetworkingFactory {
    let workerThread: JivoFoundation.JVIDispatchThread
    let networkingHelper: INetworkingHelper
    let socketDriver: ILiveConnectionDriver
    let restConnectionDriver: IRestConnectionDriver
    let localeProvider: JVILocaleProvider
    let uuidProvider: IUUIDProvider
    let preferencesDriver: IPreferencesDriver
    let keychainDriver: IKeychainDriver
    let hostProvider: (URL, String) -> URL?
    
    func build() -> INetworking {
        let networkSubSocket = NetworkingSubSocket(
            identifier: UUID(),
            driver: socketDriver,
            networkingThread: workerThread,
            behavior: .json
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
            hostProvider: hostProvider
        )
    }
}
