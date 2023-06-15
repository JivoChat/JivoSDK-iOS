//  
//  RTEModulePipeline.swift
//  App
//
//  Created by Stan Potemkin on 15.06.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

protocol AnyRTEModulePipeline: AnyObject {
}

class RTEModulePipeline<CoreEvent, PresenterUpdate, ViewIntent, JointInput, View: IRTEModulePipelineViewHandler>
: RTEModulePipelineViewNotifier<ViewIntent>
, AnyRTEModulePipeline
, IRTEModulePipelineCoreNotifier
, IRTEModulePipelinePresenterNotifier
, IRTEModulePipelineJointNotifier
where View.PresenterUpdate == PresenterUpdate {
    var linkedCore: RTEModulePipelineCoreHandler<ViewIntent, JointInput>?
    var linkedPresenter: RTEModulePipelinePresenterHandler<ViewIntent, CoreEvent, JointInput>?
    var linkedJoint: RTEModulePipelineJointHandler<CoreEvent, ViewIntent>?
    weak var linkedView: View?
    
    var view: View! {
        return linkedView
    }
    
    var joint: RTEModulePipelineJointHandler<CoreEvent, ViewIntent> {
        return linkedJoint!
    }
    
    func linkCore(_ ref: RTEModulePipelineCoreHandler<ViewIntent, JointInput>) {
        linkedCore = ref
    }

    func linkPresenter(_ ref: RTEModulePipelinePresenterHandler<ViewIntent, CoreEvent, JointInput>) {
        linkedPresenter = ref
    }

    func linkJoint(_ ref: RTEModulePipelineJointHandler<CoreEvent, ViewIntent>) {
        linkedJoint = ref
    }
    
    func linkView(_ ref: View) {
        linkedView = ref
    }

    func notify(event: CoreEvent) {
        linkedPresenter?.handleCore(event: event)
        linkedJoint?.handleCore(event: event)
    }
    
    func notifyPresenterJoint(event: CoreEvent) {
        notify(event: event)
    }
    
    func notify(update: PresenterUpdate) {
        linkedView?.handlePresenter(update: update)
    }
    
    func notifyView(update: PresenterUpdate) {
        notify(update: update)
    }
    
    func notify(input: JointInput) {
        linkedCore?.handleJoint(input: input)
        linkedPresenter?.handleJoint(input: input)
    }

    func notifyCorePresenter(input: JointInput) {
        notify(input: input)
    }

    override func notify(intent: ViewIntent) {
        linkedCore?.handleView(intent: intent)
        linkedPresenter?.handleView(intent: intent)
        linkedJoint?.handleView(intent: intent)
    }
}
