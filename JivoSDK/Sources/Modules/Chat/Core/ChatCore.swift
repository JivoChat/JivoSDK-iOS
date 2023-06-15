//
//  ChatCore.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 21.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import JMTimelineKit
import JMCodingKit
import DTCollectionViewManager

import AVFoundation
import MobileCoreServices
import Photos
import PhotosUI
import UIKit

//final class ChatCore: SdkModuleCore<ChatStorage, ChatCoreUpdate, ChatCoreRequest, ChatJointInput> {
    // MARK: - Constants
    
    // MARK: - Public properties
    
//    let timelineInteractor: ChatTimelineInteractor
    
    // MARK: - Private properties
    
//    private var chat: JVChat?
//    private var channelAgents: MemoryRepository<Int, ChatModuleAgent>
//    private var chatAgents: MemoryRepository<Int, ChatModuleAgent>
//
//    private let engine: ITrunk
//    private let uiConfig: ChatModuleUIConfig
//    private let maxImageDiskCacheSize: UInt
//
//    private let timelineController: JMTimelineController<ChatTimelineInteractor>
//    private let timelineProvider: ChatTimelineProvider
//    private let chatHistory: ChatHistory
//    private let chatTimelineFactory: ChatTimelineFactory
//
//    private let documentPickerDelegateAdapter = DocumentPickerDelegateAdapter()
//
//    private weak var chatManager: IChatManager?
//    private var chatEventObserver: JVBroadcastObserver<ChatEvent>?
//    private weak var databaseDriver: JVIDatabaseDriver?
//    private weak var clientContext: IUserContext?
//    private var clientContextObserver: JVBroadcastObserver<ClientContextEvent>?
//    private var messageHistoryRequestTimer: Timer?
//
//    private var filePickerCallback: ((URL?) -> Void)?
//
//    private let photoRequestReason = UUID(uuidString: "00000000-F000-0000-0000-000000000010") ?? UUID()
//
//    private var selectedMessage: JVMessage?
//    private var isHistoryPerformingUpdates = false
//    private var allHistoryLoaded = false
    
    // MARK: - Init
    
//    init(engine: ITrunk, uiConfig: ChatModuleUIConfig, maxImageDiskCacheSize: UInt) {
//        self.engine = engine
//        self.uiConfig = uiConfig
//        self.maxImageDiskCacheSize = maxImageDiskCacheSize
//
//        channelAgents = MemoryRepository(
//            indexItemsBy: \.id,
//            wasItemUpdated: { oldAgent, newAgent in
//                let wasItemUpdated = oldAgent.id != newAgent.id ||
//                    oldAgent.name != newAgent.name ||
//                    oldAgent.avatarLink != newAgent.avatarLink
//                return wasItemUpdated
//            }
//        )
//        chatAgents = MemoryRepository(indexItemsBy: \.id)
//
//        let storage = ChatStorage()
//
//        timelineProvider = ChatTimelineProvider(
//            client: chat?.client,
//            formattingProvider: engine.providers.formattingProvider,
//            remoteStorageService: engine.services.remoteStorageService,
//            mentionProvider: engine.providers.mentionRetriever
//        )
//
//        timelineInteractor = ChatTimelineInteractor(
//            chatManager: engine.managers.chatManager,
//            remoteStorageService: engine.services.remoteStorageService
//        )
//
//        chatTimelineFactory = ChatTimelineFactory(
//            userContext: engine.clientContext,
//            databaseDriver: engine.drivers.databaseDriver,
//            systemMessagingService: engine.services.systemMessagingService,
//            provider: timelineProvider,
//            interactor: timelineInteractor,
//            isGroup: (chat?.isGroup == true),
//            disablingOptions: [.clientUserpic],
//            botStyle: .outer,
//            outcomingPalette: uiConfig.outcomingPalette
//        )
//
//        timelineController = JMTimelineController(
//            factory: chatTimelineFactory,
//            cache: engine.timelineCache,
//            maxImageDiskCacheSize: 15 * 1024 * 1024
//        )
//
//        chatHistory = ChatHistory(
//            timelineHistory: timelineController.history,
//            databaseDriver: engine.drivers.databaseDriver,
//            factory: chatTimelineFactory,
//            collectionViewManager: timelineController.manager,
//            chat: chat,
//            chatCacheService: engine.services.chatCacheService,
//            timelineCache: timelineController.cache,
//            workerThread: engine.threads.worker
//        )
//
//        chatManager = engine.managers.chatManager
//        databaseDriver = engine.drivers.databaseDriver
//        clientContext = engine.clientContext
//
//        super.init(storage: storage)
//
//        engine.managers.chatManager.hasActiveChat = true
//
//        timelineInteractor.mediaBecameUnavailableHandler = { [weak self] url, mime in
//            self?.mediaBecameUnavailableHandler(url: url, mime: mime)
//        }
//
//        timelineController.lastItemAppearHandler = { [weak self] in
//            guard let `self` = self,
//                !self.isHistoryPerformingUpdates,
//                !self.allHistoryLoaded,
//                let earliestMessage = self.chatHistory.messages.first(where: { $0._sendingFailed == false })
//            else { return }
//
//            self.isHistoryPerformingUpdates = true
//            self.chatManager?.requestMessageHistory(fromMessageWithId: earliestMessage.ID, behavior: .force)
//            self.setLoaderHiddenState(to: false)
//
//            self.messageHistoryRequestTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] timer in
//                self?.isHistoryPerformingUpdates = false
//                timer.invalidate()
//            }
//        }
//
//        clientContextObserver = clientContext?.eventSignal.addObserver { [weak self] event in
//            DispatchQueue.main.async {
//                self?.handleClientContextEvent(event)
//            }
//        }
//
//        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
//    }
    
//    deinit {
//        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
//        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
//
//        engine.managers.sessionManager.disconnectAndTurnInactive()
//        engine.managers.chatManager.hasActiveChat = false
//    }
    
    // MARK: - ModuleCore methods
    
//    override func run() {
//        engine.managers.sessionManager.turnActive()
//    }
    
//    override func handleMediator(request: ChatCoreRequest) {
//        switch request {
//        case .attachTimelineTo(let timelineView):
//            handleAttachTimelineRequest(timelineView: timelineView)
//
//        case .detachTimelineFrom(let timelineView):
//            handleDetachTimelineRequest(timelineView: timelineView)
//
//        case .sendMessage(let message):
//            handleSendMessageRequest(message: message)
//
//        case let .messageItemDidTap(itemUUID, tap):
//            handleMessageItemDidTap(itemUUID: itemUUID, tapType: tap)
//
//        case .handleAlertActionDidTap(let alertControllerType):
//            handleAlertActionDidTap(in: alertControllerType)
//
//        case .handleAttachmentDismissButtonTap(let index):
//            handleAttachmentDismissButtonTapRequest(index: index)
//
//        case .handleViewWillAppear(let animated):
//            handleViewWillAppearRequest(animated: animated)
//
//        case .handleViewDidDisappear(let animated):
//            handleViewDidDisappearEvent(animated: animated)
//
//        case let .validateReply(text):
//            handleValidateReply(text: text)
//
//        case let .storeReply(text):
//            handleStoreReply(text: text)
//        }
//    }
//
//    override func handleJoint(input: ChatJointInput) {
//        switch input {
//        case .copyMessageText:
//            handleCopyMessageText()
//
//        case .resendMessage:
//            handleResendMessage()
//
//        case let .imagePickerDidPickImage(result):
//            handleImagePickerDidPickImage(result: result)
//        }
//    }
    
    // MARK: - Private methods
    
    // MARK: Chat event handling methods
    
//    private func handleChatEvent(_ event: ChatEvent) {
//        switch event {
//        case let .messagesUpserted(messages):
//            handleMessagesUpserted(messages: messages)
//
//        case let .messagesRemoved(messages):
//            handleMessagesRemoved(messages: messages)
//
//        case let .messageResend(message):
//            handleMessageResending(message)
//
//        case .chatObtained(let chat):
//            handleChatObtainedEvent(chat: chat)
//
//        case let .sessionInitialized(isFirstSessionInitialization):
//            handleSessionInitializedEvent(isFirst: isFirstSessionInitialization)
//
//        case .historyLoaded(let messages):
//            handleLocalHistoryLoadedEvent(messages: messages)
//
//        case .allHistoryLoaded:
//            handleAllHistoryLoadedEvent()
//
//        case .channelAgentsUpdated(let agents):
//            handleChannelAgentsUpdated(agents: agents)
//
//        case .chatAgentsUpdated(let agents):
//            handleChatAgentsUpdated(agents: agents)
//
//        case .historyErased:
//            handleHistoryErasedEvent()
//
//        case .attachmentsStartedToUpload:
//            handleAttachmentsStartedToUploadEvent()
//
//        case .attachmentsUploadSucceded:
//            handleAttachmentsUploadSucceededEvent()
//
//        case .mediaUploadFailure(let error):
//            handleMediaUploadFailure(withError: error)
//
//        case .exception(let payload):
//            handleExceptionEvent(payload)
//
//        case let .messageSending(_):
//            break
//        }
//    }
    
//    private func handleChatObtainedEvent(chat: CoreDataRef<JVChat>) {
//        self.chat = chat.resolved
//    }
//
//    private func handleMessagesUpserted(messages: [JVMessage]) {
//        let messagesToUpdate = messages.filter { chatHistory.messages.map(\.UUID).contains($0.UUID) }
//        let messagesToPopulate = messages.filter { !chatHistory.messages.map(\.UUID).contains($0.UUID) }
//
//        if !messagesToPopulate.isEmpty {
//            removeActiveMessage()
//            setLoaderHiddenState(to: true)
//            messageHistoryRequestTimer?.fire()
//        }
//
//        messagesToUpdate.forEach { updatingMessage in
//            chatHistory.update(message: updatingMessage)
//        }
//
//        chatHistory.populate(withMessages: messagesToPopulate)
//    }
    
//    private func handleMessagesRemoved(messages: [JVMessage]) {
//        messages.forEach { message in
//            chatHistory.remove(message: message)
//        }
//    }
    
//    private func appendActiveMessage(isFirstSessionInitialization: Bool) {
//        if let activeMessage = self.uiConfig.activeMessage {
//            DispatchQueue.main.asyncAfter(deadline: .now() + (isFirstSessionInitialization ? 0.5 : 0)) { [weak self] in
//                guard let `self` = self else { return }
//
//                if self.chatHistory.messages.isEmpty {
//                    let activeMessage = self.buildActiveMessage(withText: activeMessage)
//                    self.chatHistory.populate(withMessages: [activeMessage])
//                }
//            }
//        }
//    }
//
//    private func removeActiveMessage() {
//        if let activeMessage = chatHistory.messages.first(where: { $0.UUID == "activeMessage" }) {
//            chatHistory.remove(message: activeMessage)
//        }
//    }
//
//    private func handleMessageResending(_ message: JVMessage) {
//        chatHistory.remove(message: message)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
//            if not(message.status == JVMessageStatus.delivered) {
//                self?.chatHistory.update(message: message)
//            }
//        }
//    }
//
//    private func handleSessionInitializedEvent(isFirst isFirstSessionInitialization: Bool) {
//        appendActiveMessage(isFirstSessionInitialization: isFirstSessionInitialization)
//    }
//
//    private func handleHistoryErasedEvent() {
//        chat = nil
//        chatHistory.fill(with: [], partialLoaded: false, unreadPosition: .null)
//    }
//
//    private func handleLocalHistoryLoadedEvent(messages: [CoreDataRef<JVMessage>]) {
//        let messages = messages.compactMap(\.resolved)
//        chatHistory.messages = Array<JVMessage>(messages.reversed())
//        chatHistory.fill(with: messages, partialLoaded: false, unreadPosition: .null)
////        chatHistory.populate(withMessages: chatHistory.messages)
//    }
//
//    private func handleAllHistoryLoadedEvent() {
//        allHistoryLoaded = true
//        setLoaderHiddenState(to: true)
//    }
//
//    private func handleAttachmentsStartedToUploadEvent() {
//        chatHistory.setBottomItem(
//            chatTimelineFactory.generateSystemItem(
//                icon: nil,
//                meta: engine.services.systemMessagingService.generateMediaUploading(
//                    comment: nil
//                ),
//                buttons: [],
//                countable: false
//            )
//        )
//    }
//
//    private func handleAttachmentsUploadSucceededEvent() {
//        chatHistory.setBottomItem(nil)
//    }
//
//    private func handleMediaUploadFailure(withError error: MediaUploadError) {
//        chatHistory.setBottomItem(nil)
//        engine.services.typingCacheService.resetInput(context: TypingContext(kind: .chat, ID: chat?.ID ?? 0))
//        notifyMediator(update: .mediaUploadFailure(withError: error))
//    }
//
//    private func handleChannelAgentsUpdated(agents: [JVAgent]) {
//        let channelAgents: [ChatModuleAgent] = agents
//            .compactMap {
//                guard let agent = validate($0) else { return nil }
//                return ChatModuleAgent(
//                    id: agent.ID,
//                    name: agent._displayName,
//                    avatarLink: agent._avatarLink ?? "",
//                    status: ChatModuleAgent.Status(agentState: agent.state)
//                )
//            }
//
//        self.channelAgents.upsert(channelAgents) { updatedChannelAgents in
//            self.chatHistory.reloadMessages { message in
//                if let senderAgentId = message.senderAgent?.ID {
//                    return updatedChannelAgents.map(\.id).contains(senderAgentId)
//                } else {
//                    return false
//                }
//            }
//        }
//    }
//
//    private func handleChatAgentsUpdated(agents: [JVAgent]) {
//        let chatAgents: [ChatModuleAgent] = agents
//            .compactMap {
//                guard let agent = validate($0) else { return nil }
//                return ChatModuleAgent(
//                    id: agent.ID,
//                    name: agent._displayName,
//                    avatarLink: agent._avatarLink ?? "",
//                    status: ChatModuleAgent.Status(agentState: agent.state)
//                )
//            }
//
//        self.chatAgents.upsert(chatAgents)
//
//        notifyMediator(update: .chatAgentsUpdated(agents: chatAgents.filter {
//            $0.status == .active
//        }))
//
//        handleChannelAgentsUpdated(agents: agents)
//    }
//
//    private func handleExceptionEvent(_ payload: IProtoEventSubjectPayloadAny) {
//        journal {"ChatManager exception: \(payload)"}
//    }
    
    // MARK: ClinetContext event handling methods
    
//    private func handleClientContextEvent(_ event: ClientContextEvent) {
//        switch event {
//        case let .licenseStateUpdated(licenseState):
//            switch licenseState {
//            case .licensed:
//                notifyMediator(update: .licenseStateUpdated(to: .licensed))
//
//            case .unlicensed:
//                notifyMediator(update: .licenseStateUpdated(to: .unlicensed))
//
//            case .none:
//                notifyMediator(update: .licenseStateUpdated(to: .undefined))
//            }
//        default: break
//        }
//    }
    
    // MARK: Mediator requests handling
    
//    private func handleAttachTimelineRequest(timelineView: JMTimelineView<ChatTimelineInteractor>) {
//        timelineController.attach(timelineView: timelineView) { [weak self] event in
//            switch event {
//            case .latestPointOfHistory(let hasData):
//                self?.timelineFirstItemVisibleHandler(isVisible: hasData)
//            case .exceptionHappened:
//                self?.timelineExceptionHandler()
//            case .middlePointOfHistory(let item):
//                self?.messageGetsVisibleHandler(item: item)
//            default:
//                break
//            }
//        }
//
//        chatHistory.needScrollHandler = { [weak self] in
//            self?.timelineScrollHandler()
//        }
//
//        chatManager?.subscribe { [weak self] in
//            #warning("TODO: Anton Karpushko, 20.10.2021 – remove dispatching to Main-thread from ChatManager and move it to caller completion closures to transfer responsibility for thread management to callers.")
//            self?.handleChatEvent($0)
//        } completion: { [weak self] observer in
//            self?.chatEventObserver = observer
//        }
//    }
    
//    private func handleDetachTimelineRequest(timelineView: JMTimelineView<ChatTimelineInteractor>) {
//        timelineController.detach(timelineView: timelineView)
//    }
//
//    private func handleSendMessageRequest(message: String?) {
//        let attachments = engine.services.typingCacheService.currentInput?.attachments ?? []
//
//        guard validateSendingMessageContent(text: message, attachments: attachments) else {
//            journal {"Message content validation failed."}
//            return
//        }
//
//        chatManager?.sendMessage(message, withAttachments: attachments)
//        reconnectIfNeeded()
//
//        if let chat = self.chat {
//            engine.services.typingCacheService.resetInput(context: TypingContext(kind: .chat, ID: chat.ID))
//        }
//
//        notifyMediator(update: .replyValidation(succeded: false))
//    }
//
//    private func validateSendingMessageContent(text: String?, attachments: [ChatPhotoPickerObject]) -> Bool {
//        return text?.trimmed().count ?? 0 > 0 || attachments.count > 0
//    }
//
//    private func handleMessageItemDidTap(itemUUID: String, tapType: ChatTimelineTap) {
//        if let message = chatHistory.messages.first(where: { $0.UUID == itemUUID }) {
//            selectedMessage = message
//
//            let sender: JVSenderType = message.senderClient == nil ? .agent : .client
//            notifyMediator(update: .messageItemTapHandled(sender: sender, deliveryStatus: message.delivery))
//        }
//    }
//
//    private func handleAttachmentDismissButtonTapRequest(index: Int) {
//        engine.services.typingCacheService.uncache(attachmentAt: index)
//    }
//
//    private func handleAlertActionDidTap(in alertControllerType: AlertControllerType) {
//        switch alertControllerType {
//        case let .attachmentTypeSelect(action):
//            let typingCacheService = engine.services.typingCacheService
//
//            if typingCacheService.canAttachMore {
//                switch action {
//                case .imageFromLibrary:
//                    notifyMediator(update: .presentImagePicker)
//
//                case .camera:
//                    notifyMediator(update: .presentCameraPicker)
//
//                case .document:
//                    pickFile(chat: chat) { [weak self] object in
//                        self?.handleAttachment(object: object)
//                    }
//                }
//            } else {
//                notifyMediator(update: .reachedMaximumCountOfAttachments(typingCacheService.maximumCountOfAttachments))
//            }
//
//        default: break
//        }
//    }
    
    // MARK: Joint input handling
    
//    private func handleCopyMessageText() {
//        var stringToCopy: String?
//
//        switch selectedMessage?.content {
//        case let .text(message):
//            stringToCopy = message
//
//        case let .photo(_, _, link, _, _, _):
//            stringToCopy = link
//
//        case let .file(_, _, link, _):
//            stringToCopy = link
//
//        default: break
//        }
//
//        UIPasteboard.general.string = stringToCopy
//    }
//
//    private func handleResendMessage() {
//        reconnectIfNeeded()
//        if let uuid = selectedMessage?.UUID {
//            chatManager?.resendMessage(uuid: uuid)
//        }
//    }
//
//    private func handleImagePickerDidPickImage(result: Result<UIImage, ImagePickerError>) {
//        switch result {
//        case let .success(image):
//            handleMeta(.image(image)) { [weak self] chatPhotoPickerObject in
//                self?.handleAttachment(object: chatPhotoPickerObject)
//            }
//        default: break
//        }
//    }
//
//    private func handleValidateReply(text: String?) {
//        let attachments = engine.services.typingCacheService.currentInput?.attachments ?? []
//        let isValid = validateSendingMessageContent(text: text, attachments: attachments)
//        notifyMediator(update: .replyValidation(succeded: isValid))
//    }
//
//    private func handleStoreReply(text: String?) {
//        if not(text?.trimmed().isEmpty ?? true) {
//            engine.services.typingCacheService.cache(text: text)
//        } else {
//            engine.services.typingCacheService.cache(text: nil)
//        }
//    }
    
    // MARK: Other private methods
    
//    @objc private func applicationDidBecomeActive() {
//        reconnectIfNeeded()
//    }
//
//    @objc private func applicationDidEnterBackground() {
//        engine.managers.sessionManager.disconnect()
//    }
//
//    private func mediaBecameUnavailableHandler(url: URL, mime: String?) {
//        notifyMediator(update: .needsToDismissBrowser)
//    }
    
//    private func setLoaderHiddenState(to isHidden: Bool) {
//        if isHidden {
//            chatHistory.setTopItem(nil)
//        } else {
//            chatHistory.setTopItem(
//                JMTimelineLoaderItem(
//                    UUID: UUID().uuidString,
//                    date: Date.distantPast,
//                    object: JMTimelineLoaderObject(),
//                    style: JMTimelineItemStyle(
//                        margins: .zero,
//                        groupingCoef: 0,
//                        contentStyle: JMTimelineLoaderStyle(
//                            waitingIndicatorStyle: .auto
//                        )
//                    ),
//                    extra: JMTimelineExtraOptions(
//                        reactions: [],
//                        actions: []
//                    ),
//                    countable: false,
//                    cachable: true,
//                    provider: self.timelineProvider,
//                    interactor: self.timelineInteractor
//                )
//            )
//        }
//    }
    
//    private func handleAttachmentDismiss(index: Int) {
//        engine.services.typingCacheService.uncache(attachmentAt: index)
//    }
//
//    private func timelineFirstItemVisibleHandler(isVisible: Bool) {
//        let fullAccess = (validate(chat)?.client == nil)
//        let typingAllowance = fullAccess || not(isVisible)
//        notifyMediator(update: .typingAllowanceUpdated(to: typingAllowance))
//    }
//
//    private func timelineScrollHandler() {
//        notifyMediator(update: .timelineScroll)
//    }
//
//    private func timelineExceptionHandler() {
//        notifyMediator(update: .timelineException)
//    }
//
//    private func messageGetsVisibleHandler(item: JMTimelineItem) {
//        guard let message = databaseDriver?.message(for: item.uid) else {
//            return
//        }
//
//        chatManager?.requestMessageHistory(
//            fromMessageWithId: message.ID,
//            behavior: .actualize)
//    }
//
//    private func handleMeta(_ meta: ChatPickedMeta?, callback: @escaping (ChatPhotoPickerObject) -> Void) {
////        guard let chat = chat, let recipient = chat.recipient else { return }
//        let recipient = JVSender(type: .agent, ID: 0)
//
//        switch meta {
//        case .none:
//            return
//
//        case .asset(let asset)?:
//            let uuid = UUID()
//            engine.services.mediaRequestService.request(
//                asset: asset,
//                recipient: recipient,
//                reasonUUID: photoRequestReason,
//                sizeKind: .export,
//                callback: { [callback = callback] response in
//                    switch response {
//                    case .progress(let progress):
//                        callback(
//                            ChatPhotoPickerObject(
//                                uuid: uuid,
//                                payload: .progress(progress)
//                            )
//                        )
//
//                    case .photo(let image, let url, let date, let name):
//                        callback(
//                            ChatPhotoPickerObject(
//                                uuid: uuid,
//                                payload: .image(
//                                    ChatPhotoPickerImageMeta(
//                                        image: image,
//                                        url: url,
//                                        date: date,
//                                        name: name
//                                    )
//                                )
//                            )
//                        )
//
//                    case .video(let url):
//                        callback(
//                            ChatPhotoPickerObject(
//                                uuid: uuid,
//                                payload: .file(
//                                    ChatPhotoPickerFileMeta(
//                                        url: url,
//                                        name: url.lastPathComponent,
//                                        size: url.fileSize() ?? 0
//                                    )
//                                )
//                            )
//                        )
//                    }
//                }
//            )
//
//        case .image(let image)?:
//            callback(
//                ChatPhotoPickerObject(
//                    uuid: UUID(),
//                    payload: .image(
//                        ChatPhotoPickerImageMeta(
//                            image: image,
//                            url: nil,
//                            date: nil,
//                            name: nil
//                        )
//                    )
//                )
//            )
//
//        case .url(let url)?:
//            callback(
//                ChatPhotoPickerObject(
//                    uuid: UUID(),
//                    payload: .file(
//                        ChatPhotoPickerFileMeta(
//                            url: url,
//                            name: url.lastPathComponent,
//                            size: url.fileSize() ?? 0
//                        )
//                    )
//                )
//            )
//        }
//    }
//
//    private func buildActiveMessage(withText text: String) -> JVMessage {
//        let message = JVMessage(localizer: loc)
//        message._UUID = "activeMessage"
//        message._text = text
//        message._date = Date()
//        message._senderAgent = JVAgent()
//
//        return message
//    }
//}
