//
//  ChatView.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 21.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit
import JMTimelineKit
import JMRepicKit


// MARK: - Fileprivate constants

fileprivate let JIVO_BUSINESS_CHAT_VIEW_HEIGHT = CGFloat(30)

//final class ChatView: SdkModuleView<ChatViewUpdate, ChatViewEvent>, NavigationBarConfigurator {
//
//    // MARK: - Public properties
//
//    private(set) var collectionView: UICollectionView?
//
//    // MARK: - Private properties
//
//    private lazy var chatReplyControl = ChatReplyControl()
//    private lazy var titleBarView = TitleBarView()
//    private lazy var jivoBusinessChatView = JivoBusinessChatView()
//
//    private let timelineInteractor: ChatTimelineInteractor
//    private let uiConfig: ChatModuleUIConfig
//
//    private let keyboardObservingBar = BABFrameObservingInputAccessoryView()
//    private var keyboardHeight = CGFloat(0)
//
//    private var isPresentedModally: Bool {
//        return navigationController?.isBeingPresented ?? false
//    }
//
//    // MARK: - Init
//
//    init(engine: ITrunk?, timelineInteractor: ChatTimelineInteractor, uiConfig: ChatModuleUIConfig) {
//        self.timelineInteractor = timelineInteractor
//        self.uiConfig = uiConfig
//
//        super.init(engine: engine)
//
//        hidesBottomBarWhenPushed = true
//
//        titleBarView.icon = uiConfig.icon
//        titleBarView.titleLabelText = uiConfig.titlePlaceholder
//        titleBarView.titleLabelTextColor = uiConfig.titleColor
//        titleBarView.subtitleLabelText = uiConfig.subtitleCaption
//        titleBarView.subtitleLabelTextColor = uiConfig.subtitleColor
//
//        chatReplyControl.placeholder = uiConfig.inputPlaceholder
//        chatReplyControl.text = uiConfig.inputPrefill
//        chatReplyControl.tintColor = uiConfig.outcomingPalette?.inputTintColor
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    deinit {
//        if let timelineView = collectionView as? JMTimelineView<ChatTimelineInteractor> {
//            notifyMediator(event: .detachTimelineFrom(timelineView: timelineView))
//        }
//    }
//
//    // MARK: - Lifecycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        setup()
//        applyStyle()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        notifyMediator(event: .viewWillAppear(animated: animated))
//    }
//
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//
//        notifyMediator(event: .viewDidDisappear(animated: animated))
//    }
    
    // MARK: - ModuleView methods
    
//    override func handleMediator(update: ChatViewUpdate) {
//        switch update {
//        case .typingAllowanceUpdated(let isAllowed):
//            handleTypingAllowanceUpdate(isAllowed: isAllowed)
//
//        case .timelineScroll:
//            handleTimelineScrollUpdate()
//
//        case .timelineException:
//            handleTimelineExceptionUpdate()
//
//        case let .titleBarViewDataUpdate(update):
//            handleTitleBarViewDataUpdate(update)
//
//        case .attachmentUpdated(let attachment):
//            handleAttachmentUpdatedUpdate(attachment: attachment)
//
//        case .documentPickerPrepared(let documentPicker):
//            handleDocumentPickerPreparedUpdate(documentPicker)
//
//        case .documentPickerDidPickDocument:
//            handleDocumentPickerDidPickDocument()
//
//        case .reachedMaximumCountOfAttachments(let count):
//            handleReachedMaximumCountOfAttachmentsUpdate(count)
//
//        case .mediaUploadFailure(let error):
//            handleMediaUploadFailure(withError: error)
//
//        case .viewForPresentingNeeded:
//            handleViewForPresentingNeededUpdated()
//
//        case let .replyValidation(succeded):
//            handleReplyValidation(succeded: succeded)
//
//        case let .typingCacheTextObtained(text):
//            handleTypingCacheTextObtained(text)
//
//        case let .licenseStateUpdated(licenseState):
//            handleLicenseStateUpdated(to: licenseState)
//        }
//    }
    
    // MARK: - Private methods
    
    // MARK: Mediator updates handling
    
//    private func handleTypingAllowanceUpdate(isAllowed: Bool) {
//        self?.handleTypingAllowed(allowed)
//    }
    
//    private func handleTimelineScrollUpdate() {
//        scrollToBottom()
//    }
//
//    private func handleTimelineExceptionUpdate() {
//        DispatchQueue.main.async { [weak self] in
//            self?.recreateTableView()
//        }
//    }
    
//    private func handleTitleBarViewDataUpdate(_ update: ChatViewUpdate.TitleBarViewDataUpdateType) {
//        switch update {
//        case let .agents(agents):
//            handleTitleBarAgentsUpdate(agents: agents)
//
//        case let .noData(iconStub, titleStub, subtitleStub):
//            handleTitleBarNoDataUpdate(iconStub: iconStub, titleStub: titleStub, subtitleStub: subtitleStub)
//        }
//    }
//
//    private func handleTitleBarAgentsUpdate(agents: [ChatModuleAgent]) {
//        if agents.count <= 1 {
//            guard let agent = agents.first else { return }
//            titleControl.titleLabelText = agent.name
//            loadAvatar(from: agent.avatarLink) { [weak self] avatar in
//                self?.titleControl.icon = avatar ?? self?.uiConfig.icon
//            }
//        } else {
//            let title: String = agents
//                .compactMap {
//                    $0.name
//                        .split(separator: " ")
//                        .first
//                        .flatMap(String.init)
//                }
//                .joined(separator: ", ")
//            titleControl.titleLabelText = title
//            titleControl.icon = nil
//        }
//    }
//
//    private func handleTitleBarNoDataUpdate(iconStub: UIImage?, titleStub: String, subtitleStub: String) {
//        titleControl.icon = iconStub
//        titleControl.titleLabelText = titleStub
//        titleControl.subtitleLabelText = subtitleStub
//    }
    
//    private func loadAvatar(from url: String, completion: @escaping (UIImage?) -> Void) {
//        if let url = URL(string: url) {
//            let task = URLSession.shared.dataTask(
//                with: URLRequest(url: url),
//                completionHandler: { data, response, error in
//                    DispatchQueue.main.async {
//                        completion(data.flatMap(UIImage.init(data:)))
//                    }
//                })
//            task.resume()
//        } else {
//            titleControl.icon = uiConfig.icon
//        }
//    }
    
//    private func handleMediaUploadFailure(withError error: MediaUploadError) {
//        notifyMediator(event: .viewDidPrepareForMediaUploadFailureAlert(over: self, withError: error))
//    }
    
//    private func handleViewForPresentingNeededUpdated() {
//        notifyMediator(event: .preparedViewForOptionsPresenting(self))
//    }
    
//    private func handleReplyValidation(succeded: Bool) {
//        chatReplyControl.isActive = succeded
//    }
//
//    private func handleTypingCacheTextObtained(_ text: String) {
//        chatReplyControl.text = text
//    }
//
//    private func handleLicenseStateUpdated(to licenseState: ChatModuleLicenseState) {
//        switch licenseState {
//        case .undefined:
//            chatReplyControl.isAddAttachmentButtonState = .inactive
//
//        case .unlicensed:
//            chatReplyControl.isAddAttachmentButtonState = .hidden
//
//        case .licensed:
//            chatReplyControl.isAddAttachmentButtonState = .active
//        }
//    }
//
//    // MARK: View events handling
//
//    @objc private func viewDidTap(_ sender: UITapGestureRecognizer) {
//        view.endEditing(true)
//    }
//
//    @objc private func cancelButtonDidTap(_ sender: UIButton) {
//        dismiss(animated: true)
//    }
//
//    private func addAttachmentsButtonDidTap(_ sender: UIButton) {
//        let alertController = buildAttachmentTypeAlertController()
//        alertController.popoverPresentationController?.sourceView = view
//        alertController.popoverPresentationController?.sourceRect = sender.convert(sender.bounds, to: view)
//        present(alertController, animated: true)
//    }
//
//    private func sendButtonDidLongPress(_ sender: UIButton) {
//        let alertController = buildDeveloperMenuAlertController()
//        alertController.popoverPresentationController?.sourceView = view
//        alertController.popoverPresentationController?.sourceRect = sender.convert(sender.bounds, to: view)
//        present(alertController, animated: true)
//    }
//
//    private func attachmentDismissButtonDidTap(index: Int) {
//        chatReplyControl.removeAttachment(at: index)
//        notifyMediator(event: .attachmentDismissButtonTap(index: index))
//    }
//
//    private func sendLogsAlertActionDidTap(_ sender: UIAlertAction) {
//        notifyMediator(event: .alertActionDidTap(in: .developerMenu(.sendLogs)))
//    }
    
//    private func simulateCrashActionDidTap(_ sender: UIAlertAction) {
//        let numbers = [0]
//        let _ = numbers[1]
//    }
    
//}
