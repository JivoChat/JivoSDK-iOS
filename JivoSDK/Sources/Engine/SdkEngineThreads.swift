//
//  SdkEngineThreads.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 13.10.2021.
//

import Foundation
import JivoFoundation

struct SdkEngineThreads {
    let workerThread: JVIDispatchThread
}

struct SdkEngineThreadsFactory {
    func build() -> SdkEngineThreads {
        return SdkEngineThreads(
            workerThread: JVDispatchThread(caption: "jivosdk.engine.queue")
        )
    }
}
