//  
//  EmailSendingJoint.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 25.08.2021.
//

import Foundation

final class EmailSendingJoint: SdkModuleJoint<EmailSendingJointInput, EmailSendingJointOutput> {
    private let engine: ISdkEngine
    
    init(engine: ISdkEngine) {
        self.engine = engine
    }
}
