//
//  SdkNetworkingEventDispatcher.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 16.02.2021.
//

import Foundation

protocol ISdkNetworkingEventDispatcherFactory {
    func build() -> INetworkingEventDispatcher
}

struct SdkNetworkingEventDispatcherFactory: ISdkNetworkingEventDispatcherFactory {
    let outputThread: JVIDispatchThread
    let parsingQueue: DispatchQueue
    let slicer: NetworkingSlicer
    
    func build() -> INetworkingEventDispatcher {
        let networkEventDispatcher = NetworkingEventDispatcher(
            outputThread: outputThread,
            parsingQueue: parsingQueue,
            slicer: slicer
        )
        
        return networkEventDispatcher
    }
}
