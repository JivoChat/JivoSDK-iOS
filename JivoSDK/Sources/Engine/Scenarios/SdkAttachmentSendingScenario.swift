//
//  AttachmentSendingWorkflow.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 20.11.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

struct SdkAttachmentSendingScenarioEnv: OptionSet {
    let rawValue: Int
    static let upload = Self(rawValue: 1 << 0)
}

final class SdkAttachmentSendingScenario: BaseWorkflow<SdkAttachmentSendingScenarioEnv> {
    private let chatManager: ISdkChatManager
    private let chatRef: DatabaseEntityRef<ChatEntity>
    private let object: ChatPhotoPickerObject
    
    init(chatManager: ISdkChatManager,
         chatRef: DatabaseEntityRef<ChatEntity>,
         object: ChatPhotoPickerObject) {
        self.chatManager = chatManager
        self.chatRef = chatRef
        self.object = object
        
        super.init(type: "attachment_sending_\(object.uuid)")
    }
    
    deinit {
        
    }
    
    public override func main() {
        super.main()
//        defer { cleanup() }
//
//        lock()
//        if isCancelled { return }
//
//        DispatchQueue.main.async { [weak self] in
//            self?.upload()
//        }
//
//        finish()
    }
    
//    private func upload() {
//        guard let chat = validate(chat.resolved) else {
//            return
//        }
//
//        switch object.payload {
//        case .progress:
//            return
//
//        case .image(let meta):
//            chatManager.addUploading(chatID: chat.ID, subject: .image(meta.image)) { [unowned self] result in
//                if let chat: Chat = self.chatRef.resolved {
//                    self.chatManager.sendUpload(chat: chat, mode: .image, result: result)
//                }
//            }
//
//        case .file(let meta):
//            guard FileManager.default.fileExists(atPath: meta.url.path) else {
//                self.next(unlock: .upload)
//                return
//            }
//
//            chatManager.addUploading(chatID: chat.ID, subject: .file(meta.url)) { [unowned self] result in
//                if let chat: Chat = self.chatRef.resolved {
//                    self.chatManager.sendUpload(chat: chat, mode: .file, result: result)
//                }
//
//                self.next(unlock: .upload)
//            }
//        }
//    }
}
