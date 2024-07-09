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

enum SdkChatModuleLicenseState {
    case undefined // when we haven't received the license data yet
    case unlicensed
    case licensed // demo- or pro-license
}

final class ChatModuleState {
    let photoRequestReason = UUID()
    let uiConfig: SdkChatModuleVisualConfig
    var authorizationState: SessionAuthorizationState
    var recentStartupMode: SdkSessionManagerStartupMode
    
    var licenseState = SdkChatModuleLicenseState.undefined
    var activeAgents = [ChatModuleAgent]()
    var selectedMessageMeta: (sender: JVSenderType, deliveryStatus: JVMessageDelivery)?
    
    var placeholderForInput = String()
    var inputText = String()
    var isForeground: Bool
    
    init(uiConfig: SdkChatModuleVisualConfig, authorizationState: SessionAuthorizationState, recentStartupMode: SdkSessionManagerStartupMode) {
        self.uiConfig = uiConfig
        self.authorizationState = authorizationState
        self.recentStartupMode = recentStartupMode
        
        inputText = uiConfig.inputPrefill
        isForeground = UIApplication.shared.applicationState.jv_isOnscreen
    }
}
