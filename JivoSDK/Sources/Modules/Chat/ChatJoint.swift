//  
//  ChatJoint.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 21.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation


//final class ChatJoint: SdkModuleJoint<ChatJointInput, ChatJointOutput> {
//    private let engine: ITrunk
//
//    init(engine: ITrunk) {
//        self.engine = engine
//    }
//
//    override func handleMediator(event: ChatJointOutput) {
//        switch event {
//        case let .goTo(url, mime, presentingViewController):
//            broadcast(.goTo(url: url, mime: mime, presentingViewController: presentingViewController))
//
//        case .needsToDismissBrowser:
//            broadcast(.needsToDismissBrowser)
//
//        case let .viewDidPrepareForMediaUploadFailureAlert(presentingViewController, error):
//            broadcast(.viewDidPrepareForMediaUploadFailureAlert(over: presentingViewController, withError: error))
//
//        case let .optionsMenuPresentingNeeded(options, presentingViewController):
//            broadcast(.optionsMenuPresentingNeeded(withOptions: options, over: presentingViewController))
//
//        case .sendLogsScreenPresentingNeeded:
//            broadcast(.sendLogsScreenPresentingNeeded)
//
//        case .presentImagePicker:
//            broadcast(.presentImagePicker)
//
//        case .presentCameraPicker:
//            broadcast(.presentCameraPicker)
//        }
//    }
    
//    func input(_ input: ChatJointInput) {
//        switch input {
//        case .copyMessageText:
//            notifyCore(request: .copyMessageText)
//
//        case .resendMessage:
//            notifyCore(request: .resendMessage)
//
//        case let .imagePickerDidPickImage(result):
//            notifyCore(request: .imagePickerDidPickImage(result))
//        }
//    }
//}
