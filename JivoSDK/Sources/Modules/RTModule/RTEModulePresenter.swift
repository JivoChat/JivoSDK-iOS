//  
//  RTEModulePresenter.swift
//  App
//
//  Created by Stan Potemkin on 15.06.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

protocol IRTEModulePipelinePresenterNotifier: AnyObject {
    associatedtype PresenterUpdate
    func notify(update: PresenterUpdate)
    func notifyView(update: PresenterUpdate)
}

class RTEModulePipelinePresenterNotifier<PresenterUpdate>: IRTEModulePipelinePresenterNotifier {
    func notify(update: PresenterUpdate) {}
    func notifyView(update: PresenterUpdate) {}
}

class RTEModulePipelinePresenterHandler<ViewIntent, CoreEvent, JointInput> {
    func handleView(intent: ViewIntent) {}
    func handleCore(event: CoreEvent) {}
    func handleJoint(input: JointInput) {}
}

class RTEModulePresenter<Pipeline: IRTEModulePipelinePresenterNotifier, PresenterUpdate, ViewIntent, CoreEvent, JointInput, State: AnyObject>
: RTEModulePipelinePresenterHandler<ViewIntent, CoreEvent, JointInput>
where Pipeline.PresenterUpdate == PresenterUpdate {
    private(set) weak var pipeline: Pipeline?
    internal let state: State
    
    init(pipeline: Pipeline, state: State) {
        self.pipeline = pipeline
        self.state = state
    }
    
    func update(firstAppear: Bool) {
    }
    
    override func handleView(intent: ViewIntent) {
    }
    
    override func handleCore(event: CoreEvent) {
    }
    
    override func handleJoint(input: JointInput) {
    }
}
