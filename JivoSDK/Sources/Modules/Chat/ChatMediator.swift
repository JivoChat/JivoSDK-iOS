//
//  ChatMediator.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 21.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import JMRepicKit


/*
final class ChatMediator: SdkModuleMediator<ChatStorage, ChatCoreUpdate, ChatViewUpdate, ChatViewEvent, ChatCoreRequest, ChatJointOutput> {
    
    // MARK: - Private properties

    private let uiConfig: ChatModuleUIConfig
    
    // MARK: - Init
    
    init(uiConfig: ChatModuleUIConfig, storage: ChatStorage) {
        self.uiConfig = uiConfig
        super.init(storage: storage)
    }
    
    // MARK: - ModuleMediator methods
    
    override func handleCore(update: ChatCoreUpdate) {
        switch update {
        case .typingAllowanceUpdated(let isAllowed):
            notifyView(update: .typingAllowanceUpdated(to: isAllowed))
        
        case .timelineScroll:
            notifyView(update: .timelineScroll)
            
        case .timelineException:
            notifyView(update: .timelineException)
            
        case .chatAgentsUpdated(let agents):
            handleChatAgentsUpdated(agents: agents)
            
        case .attachmentUpdated(let attachment):
            notifyView(update: .attachmentUpdated(attachment))
            
        case .documentPickerPrepared(let documentPicker):
            notifyView(update: .documentPickerPrepared(documentPicker))
            
        case .documentPickerDidPickDocument:
            notifyView(update: .documentPickerDidPickDocument)
            
        case .reachedMaximumCountOfAttachments(let count):
            notifyView(update: .reachedMaximumCountOfAttachments(count))
            
        case .mediaUploadFailure(let error):
            notifyView(update: .mediaUploadFailure(withError: error))
            
        case let .messageItemTapHandled(sender, deliveryStatus):
            selectedMessageMeta = (sender: sender, deliveryStatus: deliveryStatus)
            
            notifyView(update: .viewForPresentingNeeded)
            
        case .replyValidation(let succeded):
            notifyView(update: .replyValidation(succeded: succeded))
            
        case .typingCacheTextObtained(let text):
            notifyView(update: .typingCacheTextObtained(text))
            
        case .needsToDismissBrowser:
            notifyJoint(output: .needsToDismissBrowser)
            
        case let .licenseStateUpdated(licenseState):
            notifyView(update: .licenseStateUpdated(to: licenseState))
            
        case .presentImagePicker:
            notifyJoint(output: .presentImagePicker)
            
        case .presentCameraPicker:
            notifyJoint(output: .presentCameraPicker)
        }
    }
    
    override func handleView(event: ChatViewEvent) {
        switch event {            
        case .attachTimelineTo(let timelineView):
            notifyCore(request: .attachTimelineTo(timelineView: timelineView))
        
        case .detachTimelineFrom(let timelineView):
            notifyCore(request: .detachTimelineFrom(timelineView: timelineView))
            
        case .sendMessage(let message):
            notifyCore(request: .sendMessage(message))
            
        case let .messageItemDidTap(itemUUID, tap):
            notifyCore(request: .messageItemDidTap(itemUUID: itemUUID, tapType: tap))
            
        case .alertActionDidTap(let alertControllerType):
            switch alertControllerType {
//            case let .developerMenu(action):
//                switch action {
//                case .sendLogs:
//                    notifyJoint(output: .sendLogsScreenPresentingNeeded)
//                }
                
            default:
                notifyCore(request: .handleAlertActionDidTap(in: alertControllerType))
            }
            
        case .attachmentDismissButtonTap(let index):
            notifyCore(request: .handleAttachmentDismissButtonTap(index: index))
            
        case .viewWillAppear(let animated):
            notifyCore(request: .handleViewWillAppear(animated: animated))
            
        case .viewDidDisappear(let animated):
            notifyCore(request: .handleViewDidDisappear(animated: animated))
            
        case let .timelineMediaItemDidTap(url, mime, presentingViewController):
            notifyJoint(output: .goTo(url: url, mime: mime, presentingViewController: presentingViewController))
            
        case let .viewDidPrepareForMediaUploadFailureAlert(presentingViewController, error):
            notifyJoint(output: .viewDidPrepareForMediaUploadFailureAlert(over: presentingViewController, withError: error))
            
        case let .preparedViewForOptionsPresenting(presentingViewController):
            handlePreparedViewForOptionsPresenting(presentingViewController)
            
        case let .replyTextFieldDidChange(text):
            notifyCore(request: .validateReply(text: text))
            notifyCore(request: .storeReply(text: text))
        }
    }
    
    // MARK: - Private methods
    
//    private func handleChatAgentsUpdated(agents: [ChatModuleAgent]) {
//        notifyView(update: .titleBarViewDataUpdate(
//            !agents.isEmpty
//                ? .agents(agents)
//                : .noData(
//                    iconStub: uiConfig.icon,
//                    titleStub: uiConfig.titlePlaceholder,
//                    subtitleStub: uiConfig.subtitleCaption
//                )
//        ))
//    }
    
//    private func handlePreparedViewForOptionsPresenting(_ presentingViewController: UIViewController) {
//        let (sender, deliveryStatus) = (selectedMessageMeta?.sender, selectedMessageMeta?.deliveryStatus)
//        var optionsNeeded: [ContextMenuOptionType] = []
//
//        switch (sender, deliveryStatus) {
//        case (.client, .failed):
//            optionsNeeded = [.copy, .resendMessage]
//
//        default:
//            optionsNeeded = [.copy]
//        }
//
//        notifyJoint(output: .optionsMenuPresentingNeeded(withOptions: optionsNeeded, over: presentingViewController))
//    }
    
//    private func repicViewFrom(link: String?) -> JMRepicView {
//        let repicView = JMRepicView(config: .standard(height: 36))
//        if let imageLink = link {
//            let repicItemSource = JMRepicItemSource.avatar(URL: URL(string: imageLink), image: nil, color: .brown, transparent: false)
//            let repicItem = JMRepicItem(backgroundColor: nil, source: repicItemSource, scale: 1.0, clipping: .disabled)
//            repicView.configure(item: repicItem)
//        }
//        return repicView
//    }
}
*/
