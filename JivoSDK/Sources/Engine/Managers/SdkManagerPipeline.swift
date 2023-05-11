//
//  SdkManagerPipeline.swift
//  SDK
//
//  Created by Stan Potemkin on 03.03.2023.
//

import Foundation

final class SdkManagerPipeline: JVBroadcastTool<SdkManagerPipelineEvent> {
    let workerThread: JVIDispatchThread
    
    init(workerThread: JVIDispatchThread) {
        self.workerThread = workerThread
        
        super.init()
    }
    
    func notify(event: SdkManagerPipelineEvent) {
        if Thread.isMainThread {
            workerThread.async { [weak self] in
                self?.broadcast(event)
            }
        }
        else {
            broadcast(event)
        }
    }
}

enum SdkManagerPipelineEvent {
    case turnActive
    case turnInactive(SdkManagerSubsystem)
}
