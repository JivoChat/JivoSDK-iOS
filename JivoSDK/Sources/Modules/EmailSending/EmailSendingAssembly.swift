//  
//  EmailSendingAssembly.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 25.08.2021.
//

import Foundation

protocol IEmailSendingStorage {
}

enum EmailSendingCoreUpdate {
}

enum EmailSendingCoreRequest {
}

enum EmailSendingViewUpdate {
}

enum EmailSendingViewEvent {
}

enum EmailSendingJointInput {
}

enum EmailSendingJointOutput {
}

func EmailSendingAssembly(dependenceis: ISdkEngine) -> SdkModule<EmailSendingView, EmailSendingJoint> {
    return SdkModuleAssembly(
        coreBuilder: {
            EmailSendingCore()
        },
        mediatorBuilder: { storage in
            EmailSendingMediator(
                storage: storage)
        },
        viewBuilder: {
            EmailSendingView(engine: dependenceis)
        },
        jointBuilder: {
            EmailSendingJoint(engine: dependenceis)
        })
}
