//  
//  ChatModuleState.swift
//  Pods
//
//  Created by Stan Potemkin on 11.08.2022.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

enum ChatModuleInputUpdate {
    case update(SdkChatReplyControl.Update)
//    case enable
//    case disable(placeholder: String)
    case fill(text: String, attachments: [ChatPhotoPickerObject])
//    case updateText(String)
    case updateAttachment(ChatPhotoPickerObject)
    case failedAttachments
    case shakeAttachments
//    case validationStatus(Bool)
}

final class ChatModuleState {
    let photoRequestReason = UUID()
    let uiConfig: ChatModuleUIConfig
    var authorizationState: SessionAuthorizationState
    
    var licenseState = ChatModuleLicenseState.undefined
    var activeAgents = [ChatModuleAgent]()
    var selectedMessageMeta: (sender: JVSenderType, deliveryStatus: JVMessageDelivery)?
    
    var placeholderForInput = String()
    var inputText = String()
    
    init(uiConfig: ChatModuleUIConfig, authorizationState: SessionAuthorizationState) {
        self.uiConfig = uiConfig
        self.authorizationState = authorizationState
        
        inputText = uiConfig.inputPrefill
    }
}
