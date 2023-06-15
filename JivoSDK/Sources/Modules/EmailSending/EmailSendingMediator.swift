//  
//  EmailSendingMediator.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 25.08.2021.
//

import Foundation

final class EmailSendingMediator: SdkModuleMediator<EmailSendingStorage, EmailSendingCoreUpdate, EmailSendingViewUpdate, EmailSendingViewEvent, EmailSendingCoreRequest, EmailSendingJointOutput> {
    override init(storage: EmailSendingStorage) {
        super.init(storage: storage)
    }
    
    override func handleCore(update: EmailSendingCoreUpdate) {
    }
    
    override func handleView(event: EmailSendingViewEvent) {
    }
}
