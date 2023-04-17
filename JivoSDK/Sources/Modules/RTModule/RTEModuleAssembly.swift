//  
//  RTEModuleAssembly.swift
//  App
//
//  Created by Stan Potemkin on 15.06.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UIKit

typealias RTEConfigTrunk = ISdkEngine
typealias RTEConfigBaseViewStandalone = SdkBaseViewController
typealias RTEConfigBaseViewNavigatable = UINavigationController

func RTEModuleAssembly<
    CoreEvent,
    PresenterUpdate,
    ViewIntent,
    JointInput,
    JointOutput,
    View: IRTEModulePipelineViewHandler,
    Pipeline: RTEModulePipeline<CoreEvent, PresenterUpdate, ViewIntent, JointInput, View>,
    State: AnyObject,
    Core: RTEModuleCore<Pipeline, CoreEvent, ViewIntent, JointInput, State>,
    Presenter: RTEModulePresenter<Pipeline, PresenterUpdate, ViewIntent, CoreEvent, JointInput, State>,
    Joint: RTEModuleJoint<Pipeline, JointOutput, JointInput, CoreEvent, ViewIntent, State>
>(pipeline: Pipeline,
 state: State,
 coreBuilder: (Pipeline, State) -> Core,
 presenterBuilder: (Pipeline, State) -> Presenter,
 viewBuilder: (RTEModulePipelineViewNotifier<ViewIntent>) -> View,
 jointBuilder: (Pipeline, State, View) -> Joint) -> RTEModule<PresenterUpdate, ViewIntent, Joint, View> {
    let core = coreBuilder(pipeline, state)
    let presenter = presenterBuilder(pipeline, state)
    let view = viewBuilder(pipeline)
    let joint = jointBuilder(pipeline, state, view)

    pipeline.linkCore(core)
    pipeline.linkPresenter(presenter)
    pipeline.linkJoint(joint)
    pipeline.linkView(view)

    core.run()
    presenter.update(firstAppear: true)

    return RTEModule(view: view, joint: joint)
}
