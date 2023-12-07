//  
//  ChatModuleState.swift
//  Pods
//
//  Created by Stan Potemkin on 11.08.2022.
//

import Foundation

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
    var recentStartupMode: SdkSessionManagerStartupMode
    
    var licenseState = ChatModuleLicenseState.undefined
    var activeAgents = [ChatModuleAgent]()
    var selectedMessageMeta: (sender: JVSenderType, deliveryStatus: JVMessageDelivery)?
    
    var placeholderForInput = String()
    var inputText = String()
    
    init(uiConfig: ChatModuleUIConfig, authorizationState: SessionAuthorizationState, recentStartupMode: SdkSessionManagerStartupMode) {
        self.uiConfig = uiConfig
        self.authorizationState = authorizationState
        self.recentStartupMode = recentStartupMode
        
        inputText = uiConfig.inputPrefill
    }
}
