//
//  SdkEngineThreads.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 13.10.2021.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

struct SdkEngineThreads {
    let workerThread: JivoFoundation.JVIDispatchThread
}

struct SdkEngineThreadsFactory {
    func build() -> SdkEngineThreads {
        return SdkEngineThreads(
            workerThread: JivoFoundation.JVDispatchThread(caption: "jivosdk.engine")
        )
    }
}
