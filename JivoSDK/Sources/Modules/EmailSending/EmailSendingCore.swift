//  
//  EmailSendingCore.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 25.08.2021.
//

import Foundation

final class EmailSendingCore: SdkModuleCore<EmailSendingStorage, EmailSendingCoreUpdate, EmailSendingCoreRequest, EmailSendingJointInput> {
    init() {
        let storage = EmailSendingStorage()
        
        super.init(storage: storage)
    }
    
    override func run() {
    }
    
    override func handleMediator(request: EmailSendingCoreRequest) {
    }
}
