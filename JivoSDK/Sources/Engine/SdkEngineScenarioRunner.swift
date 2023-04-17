//
//  SdkEngineScenarioRunner.swift
//  SDK
//
//  Created by Stan Potemkin on 28.02.2023.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

protocol ISdkEngineScenarioRunner: AnyObject {
}

final class SdkEngineScenarioRunner: ISdkEngineScenarioRunner {
    private let thread: JivoFoundation.JVIDispatchThread
    private let managers: SdkEngineManagers
    
    init(thread: JivoFoundation.JVIDispatchThread, managers: SdkEngineManagers) {
        self.thread = thread
        self.managers = managers
    }
    
    private let workflowsQueue = OperationQueue()
}
