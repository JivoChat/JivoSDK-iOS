//  
//  RTEModuleJoint.swift
//  App
//
//  Created by Stan Potemkin on 15.06.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UIKit

protocol IRTEModulePipelineJointNotifier: AnyObject {
    associatedtype JointInput
    func notify(input: JointInput)
    func notifyCorePresenter(input: JointInput)
}

class RTEModuleJointNavigationHandler: NSObject {
    internal weak var view: UIViewController?
    var navigationKinds: Set<String> { Set() }
    final func isIdenticalTo(joint: Any) -> Bool { String(reflecting: joint).dropLast(5) == String(reflecting: type(of: self)) }
    final func isResponsibleFor(navigationKind kind: String) -> Bool { navigationKinds.contains(kind) }
}

class RTEModulePipelineJointHandler<CoreEvent, ViewIntent>
: RTEModuleJointNavigationHandler {
    func handleCore(event: CoreEvent) {}
    func handleView(intent: ViewIntent) {}
}

class RTEModuleJoint<Pipeline: IRTEModulePipelineJointNotifier, JointOutput, JointInput, CoreEvent, ViewIntent, State: AnyObject>
: RTEModulePipelineJointHandler<CoreEvent, ViewIntent>
where Pipeline.JointInput == JointInput {
    private(set) weak var pipeline: Pipeline?
    internal let state: State
    private(set) weak var navigator: IRTNavigator?
    
    private var callback: ((JointOutput) -> Void)?
    
    init(pipeline: Pipeline, state: State, view: UIViewController, navigator: IRTNavigator) {
        self.pipeline = pipeline
        self.state = state
        self.navigator = navigator
        
        super.init()
        
        self.view = view
        
        navigator.add(handler: self)
    }
    
    deinit {
        navigator?.remove(handler: self)
    }
    
    func attach(callback: @escaping (JointOutput) -> Void) {
        self.callback = callback
    }
    
    func take(input: JointInput) {
        pipeline?.notify(input: input)
    }
    
    override func handleCore(event: CoreEvent) {
    }
    
    override func handleView(intent: ViewIntent) {
    }
    
    final var navigationView: UINavigationController? {
        return view as? UINavigationController
    }
    
    final func notifyOut(output: JointOutput) {
        callback?(output)
    }
}
