//  
//  RTEModuleCore.swift
//  App
//
//  Created by Stan Potemkin on 15.06.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

protocol IRTEModulePipelineCoreNotifier: AnyObject {
    associatedtype CoreEvent
    func notify(event: CoreEvent)
    func notifyPresenterJoint(event: CoreEvent)
}

class RTEModulePipelineCoreHandler<ViewIntent, JointInput> {
    func handleView(intent: ViewIntent) {}
    func handleJoint(input: JointInput) {}
}

class RTEModuleCore<Pipeline: IRTEModulePipelineCoreNotifier, CoreEvent, ViewIntent, JointInput, State: AnyObject>
: RTEModulePipelineCoreHandler<ViewIntent, JointInput>
where Pipeline.CoreEvent == CoreEvent {
    private(set) weak var pipeline: Pipeline?
    internal let state: State
    
    init(pipeline: Pipeline, state: State) {
        self.pipeline = pipeline
        self.state = state
    }
    
    func run() {
    }
    
    override func handleView(intent: ViewIntent) {
    }
    
    override func handleJoint(input: JointInput) {
    }
}
