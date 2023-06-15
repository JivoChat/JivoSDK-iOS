//
//  Module.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 21.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

struct SdkModule<View: SdkBaseViewController, Remote> {
    let view: View
    let joint: Remote
}

class SdkModuleCore<Storage, CoreUpdate, CoreRequest, JointInput> {
    let storage: Storage
    fileprivate let updateSignal = JVBroadcastTool<CoreUpdate>()
    init(storage: Storage) { self.storage = storage }
    func run() {}
    func notifyMediator(update: CoreUpdate) { updateSignal.broadcast(update) }
    func handleMediator(request: CoreRequest) {}
    func handleJoint(input: JointInput) {}
}

class SdkModuleMediator<Storage, CoreUpdate, ViewUpdate, ViewEvent, CoreRequest, JointOutput> {
    let storage: Storage
    fileprivate let updateSignal = JVBroadcastTool<ViewUpdate>()
    fileprivate let requestSignal = JVBroadcastTool<CoreRequest>()
    fileprivate let outputSignal = JVBroadcastTool<JointOutput>()
    init(storage: Storage) { self.storage = storage }
    func handleCore(update: CoreUpdate) {}
    func notifyView(update: ViewUpdate) { updateSignal.broadcast(update) }
    func handleView(event: ViewEvent) {}
    func notifyCore(request: CoreRequest) { requestSignal.broadcast(request) }
    func notifyJoint(output: JointOutput) { outputSignal.broadcast(output) }
}

class SdkModuleView<ViewUpdate, ViewEvent>: SdkBaseViewController {
    fileprivate let eventSignal = JVBroadcastTool<ViewEvent>()
    func handleMediator(update: ViewUpdate) {}
    func notifyMediator(event: ViewEvent) { eventSignal.broadcast(event) }
}

class SdkModuleJoint<JointInput, JointOutput>: JVBroadcastTool<JointOutput> {
    fileprivate let inputSignal = JVBroadcastTool<JointInput>()
    func notifyCore(request: JointInput) { inputSignal.broadcast(request) }
    func handleMediator(event: JointOutput) { broadcast(event) }
}

func SdkModuleAssembly<
    Storage, CoreUpdate, ViewUpdate, ViewEvent, CoreRequest, JointInput, JointOutput,
    Core: SdkModuleCore<Storage, CoreUpdate, CoreRequest, JointInput>,
    Mediator: SdkModuleMediator<Storage, CoreUpdate, ViewUpdate, ViewEvent, CoreRequest, JointOutput>,
    View: SdkModuleView<ViewUpdate, ViewEvent>,
    Joint: SdkModuleJoint<JointInput, JointOutput>>
(coreBuilder: () -> Core,
 mediatorBuilder: (Storage) -> Mediator,
 viewBuilder: () -> View,
 jointBuilder: () -> Joint) -> SdkModule<View, Joint> {
    let core = coreBuilder()
    let mediator = mediatorBuilder(core.storage)
    let view = viewBuilder()
    let joint = jointBuilder()
    
    view.eventSignal.attachObserver(mediator.handleView)
    mediator.updateSignal.attachObserver { [weak view] update in view?.handleMediator(update: update) }
    
    mediator.requestSignal.attachObserver(core.handleMediator)
    core.updateSignal.attachObserver { [weak mediator] update in mediator?.handleCore(update: update) }
    
    mediator.outputSignal.attachObserver(joint.handleMediator)
    joint.inputSignal.attachObserver { [weak core] input in core?.handleJoint(input: input) }
    
    core.run()
    
    return SdkModule(view: view, joint: joint)
}
