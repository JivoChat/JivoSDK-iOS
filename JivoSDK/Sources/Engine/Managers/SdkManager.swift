//
//  SdkBaseManager.swift
//  SDK
//
//  Created by Stan Potemkin on 28.02.2023.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

protocol ISdkManager: IManager {
}

struct SdkManagerSubsystem: OptionSet {
    let rawValue: Int
    static let config = Self.init(rawValue: 1 << 0)
    static let connection = Self.init(rawValue: 1 << 1)
    static let artifacts = Self.init(rawValue: 1 << 2)
    static let all = Self.init(rawValue: ~0)
}

class SdkManager: BaseManager, ISdkManager {
    private let pipeline: SdkManagerPipeline
    
    init(
        pipeline: SdkManagerPipeline,
        thread: JivoFoundation.JVIDispatchThread,
        userContext: AnyObject,
        proto: AnyObject & INetworkingEventDecoder,
        networkEventDispatcher: INetworkingEventDispatcher
    ) {
        self.pipeline = pipeline
        
        super.init(
            thread: thread,
            userContext: userContext,
            proto: proto,
            networkEventDispatcher: networkEventDispatcher)
        
        pipeline.attachObserver { [unowned self] event in
            _handlePipeline(event: event)
        }
    }
    
    final func notifyPipeline(event: SdkManagerPipelineEvent) {
        pipeline.notify(event: event)
    }
    
    func _handlePipeline(event: SdkManagerPipelineEvent) {
    }
}
