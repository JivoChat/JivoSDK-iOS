//
//  ChatAssembly.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 21.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import JMTimelineKit
import JMRepicKit

import UIKit

/*

protocol IChatStorage {}

enum ChatCoreUpdate {
    case typingAllowanceUpdated(to: Bool)
    case timelineScroll
    case timelineException
    case chatAgentsUpdated(agents: [ChatModuleAgent])
    case attachmentUpdated(_ attachment: ChatPhotoPickerObject)
    case mediaUploadFailure(withError: MediaUploadError)
    case documentPickerPrepared(_ documentPicker: UIDocumentPickerViewController)
    case documentPickerDidPickDocument
    case reachedMaximumCountOfAttachments(_ count: Int)
    case messageItemTapHandled(sender: JVSenderType, deliveryStatus: JVMessageDelivery)
    case replyValidation(succeded: Bool)
    case typingCacheTextObtained(_ text: String)
    case needsToDismissBrowser
    case licenseStateUpdated(to: ChatModuleLicenseState)
    case presentImagePicker
    case presentCameraPicker
}

enum ChatCoreRequest {
    case attachTimelineTo(timelineView: JMTimelineView<ChatTimelineInteractor>)
    case detachTimelineFrom(timelineView: JMTimelineView<ChatTimelineInteractor>)
    case sendMessage(_ message: String?)
    case messageItemDidTap(itemUUID: String, tapType: ChatTimelineTap)
    case handleAlertActionDidTap(in: AlertControllerType)
    case handleAttachmentDismissButtonTap(index: Int)
    case handleViewDidDisappear(animated: Bool)
    case handleViewWillAppear(animated: Bool)
    case validateReply(text: String?)
    case storeReply(text: String?)
}

enum ChatViewUpdate {
    case typingAllowanceUpdated(to: Bool)
    case timelineScroll
    case timelineException
    case titleBarViewDataUpdate(TitleBarViewDataUpdateType)
    case attachmentUpdated(_ attachment: ChatPhotoPickerObject)
    case documentPickerPrepared(_ documentPicker: UIDocumentPickerViewController)
    case documentPickerDidPickDocument
    case reachedMaximumCountOfAttachments(_ count: Int)
    case mediaUploadFailure(withError: MediaUploadError)
    case viewForPresentingNeeded
    case replyValidation(succeded: Bool)
    case typingCacheTextObtained(_ text: String)
    case licenseStateUpdated(to: ChatModuleLicenseState)
}

extension ChatViewUpdate {
    enum TitleBarViewDataUpdateType {
        case agents([ChatModuleAgent])
        case noData(iconStub: UIImage?, titleStub: String, subtitleStub: String)
    }
}

enum ChatViewEvent {
    case attachTimelineTo(timelineView: JMTimelineView<ChatTimelineInteractor>)
    case detachTimelineFrom(timelineView: JMTimelineView<ChatTimelineInteractor>)
    case sendMessage(_ message: String?)
    case messageItemDidTap(itemUUID: String, tapType: ChatTimelineTap)
    case preparedViewForOptionsPresenting(_ viewController: UIViewController)
    case alertActionDidTap(in: AlertControllerType)
    case attachmentDismissButtonTap(index: Int)
    case viewWillAppear(animated: Bool)
    case viewDidDisappear(animated: Bool)
    case timelineMediaItemDidTap(url: URL, mime: String?, presentingViewController: UIViewController)
    case viewDidPrepareForMediaUploadFailureAlert(over: UIViewController, withError: MediaUploadError)
    case replyTextFieldDidChange(_ text: String?)
}

enum ChatJointInput {
    case copyMessageText
    case resendMessage
    case imagePickerDidPickImage(Result<UIImage, ImagePickerError>)
}

enum ChatJointOutput {
    case goTo(url: URL, mime: String?, presentingViewController: UIViewController)
    case needsToDismissBrowser
    case viewDidPrepareForMediaUploadFailureAlert(over: UIViewController, withError: MediaUploadError)
    case optionsMenuPresentingNeeded(withOptions: [ContextMenuOptionType], over: UIViewController)
    case sendLogsScreenPresentingNeeded
    case presentImagePicker
    case presentCameraPicker
}

func ChatAssembly(
    engine: ITrunk,
    uiConfig: ChatModuleUIConfig,
    maxImageDiskCacheSize: UInt
) -> SdkModule<ChatView, ChatJoint> {
    let chatCore = ChatCore(
        engine: engine,
        uiConfig: uiConfig,
        maxImageDiskCacheSize: maxImageDiskCacheSize
    )
    let timelineInteractor = chatCore.timelineInteractor
    
    return SdkModuleAssembly(
        coreBuilder: {
            return chatCore
        },
        mediatorBuilder: { storage in
            ChatMediator(
                uiConfig: uiConfig,
                storage: storage)
        },
        viewBuilder: {
            ChatView(
                engine: engine,
                timelineInteractor: timelineInteractor,
                uiConfig: uiConfig)
        },
        jointBuilder: {
            ChatJoint(
                engine: engine)
        })
}

*/
