//
//  JVSessionHandle.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 27.03.2024.
//

import Foundation

public enum JVSessionHandleError: Error {
    case success
    case notInteractable
    case awaitingContactForm
}

/*
 Provides an ability to simulate some user actions within active chat session
 */
@objc(JVSessionHandle)
@_documentation(visibility: internal)
public final class JVSessionHandle: NSObject {
    private var canInteractWithEngine = true
    private var hasInteractedBefore = false

    /*
     Sends a message from client
     
     > Note: Can be called once per each SDK appearance
     */
    @objc(sendMessage:error:)
    public func sendMessage(text: String) throws {
        try interact { engine in
            do {
                try engine.managers.chatManager.sendMessage(
                    trigger: .api,
                    text: text,
                    attachments: .jv_empty)
            }
            catch SdkChatManagerError.awaitingContactForm {
                throw JVSessionHandleError.awaitingContactForm
            }
        }
    }
}

extension JVSessionHandle: SdkEngineAccessing {
    internal func disableInteraction() {
        canInteractWithEngine = false
    }
    
    private func interact(block: (ISdkEngine) throws -> Void) throws {
        guard canInteractWithEngine else {
            throw JVSessionHandleError.notInteractable
        }
        
        if hasInteractedBefore {
            throw JVSessionHandleError.notInteractable
        }
        else {
            try block(engine)
            hasInteractedBefore = true
        }
    }
}
