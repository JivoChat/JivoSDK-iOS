//  
//  PopupAssembly.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 30.11.2020.
//

import Foundation

protocol IPopupStorage {
}

enum PopupCoreUpdate {
}

enum PopupCoreRequest {
}

enum PopupViewUpdate {
}

enum PopupViewEvent {
}

enum PopupJointInput {
}

enum PopupJointOutput {
}

func PopupAssembly(engine: ISdkEngine) -> SdkModule<PopupView, PopupJoint> {
    return SdkModuleAssembly(
        coreBuilder: {
            PopupCore()
        },
        mediatorBuilder: { storage in
            PopupMediator(
                storage: storage)
        },
        viewBuilder: {
            PopupView(engine: engine)
        },
        jointBuilder: {
            PopupJoint(engine: engine)
        })
}
