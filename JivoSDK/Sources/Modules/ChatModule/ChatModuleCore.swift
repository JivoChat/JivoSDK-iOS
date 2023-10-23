//  
//  ChatModuleCore.swift
//  Pods
//
//  Created by Stan Potemkin on 11.08.2022.
//

import Foundation
import Photos

import JMTimelineKit
import JMMarkdownKit
import CoreData

enum ChatModuleCoreEvent {
    case hasUpdates
    case warnAbout(String)
    case journalReady(url: URL, data: Data)
    case authorizationStateUpdated
    case licenseUpdate
    case agentsUpdate
    case hasInputUpdates
    case inputUpdate(ChatModuleInputUpdate)
    case mediaUploadFailure(error: MediaUploadError)
    case messageSent
    case messageTapped
    case remoteMediaUnavailable
    case timelineScrollToBottom
    case timelineRecreate
}

enum ChatPickedMeta {
    case asset(PHAsset)
    case image(UIImage)
    case url(URL)
}

final class ChatModuleCore
: RTEModuleCore<
    ChatModulePipeline,
    ChatModuleCoreEvent,
    ChatModuleViewIntent,
    ChatModuleJointInput,
    ChatModuleState
> {
    private let workerThread: JVIDispatchThread
    private let managerPipeline: SdkManagerPipeline
    private let sessionContext: ISdkSessionContext
    private let clientContext: ISdkClientContext
    private let messagingContext: ISdkMessagingContext
    private let sessionManager: ISdkSessionManager
    private let chatManager: ISdkChatManager
    private let typingCacheService: ITypingCacheService
    private let remoteStorageService: IRemoteStorageService
    private let systemMessagingService: ISystemMessagingService
    private let chatCacheService: IChatCacheService
    private let mediaRequestService: IMediaRequestService
    private let apnsService: ISdkApnsService
    private let popupPresenterBridge: IPopupPresenterBridge
    private let networking: INetworking
    private let formattingProvider: IFormattingProvider
    private let databaseDriver: JVIDatabaseDriver
    private let mentionRetriever: JMMarkdownMentionProvider
    private let timelineFactory: ChatTimelineFactory
    private let timelineController: JMTimelineController<ChatTimelineInteractor>
    private let timelineInteractor: ChatTimelineInteractor
    private let timelineCache: JMTimelineCache
    private let uiConfig: ChatModuleUIConfig
    private let maxImageDiskCacheSize: UInt
    
    private var chat: JVChat?
    private var channelAgents: MemoryRepository<Int, ChatModuleAgent>
    private var chatAgents: MemoryRepository<Int, ChatModuleAgent>
    
    private let chatHistory: ChatHistory
    
    private let documentPickerDelegateAdapter = DocumentPickerDelegateAdapter()
    
    private var authorizationStateObserver: JVBroadcastObserver<SessionAuthorizationState>?
    private var chatEventObserver: JVBroadcastObserver<SdkChatEvent>?
    private var messagingEventObserver: JVBroadcastObserver<SdkMessagingEvent>?
    private var sessionContextObserver: JVBroadcastObserver<SdkSessionContextEvent>?
    private var clientContextObserver: JVBroadcastObserver<SdkClientContextEvent>?
    private var contactInfoStatusObserver: JVBroadcastObserver<SdkChatContactInfoStatus>?
    private var messageHistoryRequestTimer: Timer?
    
    private var filePickerCallback: ((URL?) -> Void)?
    
    private var selectedMessage: JVMessage?
    private var isHistoryPerformingUpdates = false
    private var allHistoryLoaded = false
    
    init(pipeline: ChatModulePipeline,
         state: ChatModuleState,
         workerThread: JVIDispatchThread,
         managerPipeline: SdkManagerPipeline,
         sessionContext: ISdkSessionContext,
         clientContext: ISdkClientContext,
         messagingContext: ISdkMessagingContext,
         sessionManager: ISdkSessionManager,
         chatManager: ISdkChatManager,
         typingCacheService: ITypingCacheService,
         remoteStorageService: IRemoteStorageService,
         systemMessagingService: ISystemMessagingService,
         chatCacheService: IChatCacheService,
         mediaRequestService: IMediaRequestService,
         apnsService: ISdkApnsService,
         popupPresenterBridge: IPopupPresenterBridge,
         networking: INetworking,
         formattingProvider: IFormattingProvider,
         databaseDriver: JVIDatabaseDriver,
         mentionRetriever: @escaping JMMarkdownMentionProvider,
         timelineFactory: ChatTimelineFactory,
         timelineController: JMTimelineController<ChatTimelineInteractor>,
         timelineInteractor: ChatTimelineInteractor,
         timelineCache: JMTimelineCache,
         uiConfig: ChatModuleUIConfig,
         maxImageDiskCacheSize: UInt
    ) {
        self.workerThread = workerThread
        self.managerPipeline = managerPipeline
        self.sessionContext = sessionContext
        self.clientContext = clientContext
        self.messagingContext = messagingContext
        self.sessionManager = sessionManager
        self.chatManager = chatManager
        self.typingCacheService = typingCacheService
        self.remoteStorageService = remoteStorageService
        self.systemMessagingService = systemMessagingService
        self.chatCacheService = chatCacheService
        self.mediaRequestService = mediaRequestService
        self.apnsService = apnsService
        self.popupPresenterBridge = popupPresenterBridge
        self.networking = networking
        self.formattingProvider = formattingProvider
        self.databaseDriver = databaseDriver
        self.mentionRetriever = mentionRetriever
        self.timelineFactory = timelineFactory
        self.timelineController = timelineController
        self.timelineInteractor = timelineInteractor
        self.timelineCache = timelineCache
        self.uiConfig = uiConfig
        self.maxImageDiskCacheSize = maxImageDiskCacheSize
        
        channelAgents = MemoryRepository(
            indexItemsBy: \.id,
            wasItemUpdated: { oldAgent, newAgent in
                let wasItemUpdated = oldAgent.id != newAgent.id ||
                    oldAgent.name != newAgent.name ||
                    oldAgent.avatarLink != newAgent.avatarLink
                return wasItemUpdated
            }
        )
        chatAgents = MemoryRepository(indexItemsBy: \.id)
        
        chatHistory = ChatHistory(
            timelineHistory: timelineController.history,
            databaseDriver: databaseDriver,
            factory: timelineFactory,
            collectionViewManager: timelineController.manager,
            chat: chat,
            chatCacheService: chatCacheService,
            timelineCache: timelineController.cache,
            workerThread: workerThread
        )
        
        super.init(pipeline: pipeline, state: state)
        
        authorizationStateObserver = clientContext.authorizationStateSignal.addObserver { [weak self] state in
            self?.state.authorizationState = state
            self?.pipeline?.notify(event: .authorizationStateUpdated)
        }
        
        chatHistory.needScrollHandler = { [weak self] in
            self?.timelineScrollHandler()
        }
        
        chatManager.hasActiveChat = true
        
        timelineInteractor.mediaBecameUnavailableHandler = { [weak self] url, mime in
            self?.mediaBecameUnavailableHandler(url: url, mime: mime)
        }
        
        timelineController.lastItemAppearHandler = { [weak self] in
            guard let `self` = self,
                !self.isHistoryPerformingUpdates,
                !self.allHistoryLoaded,
                let earliestMessage = self.chatHistory.messages.first(where: { $0.m_sending_failed == false })
            else { return }
            
            self.isHistoryPerformingUpdates = true
            self.chatManager.requestMessageHistory(fromMessageWithId: earliestMessage.ID, behavior: .force)
            self.setLoaderHiddenState(to: false)
            
            self.messageHistoryRequestTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] timer in
                self?.isHistoryPerformingUpdates = false
                timer.invalidate()
            }
        }
        
        sessionContextObserver = sessionContext.eventSignal.addObserver { [weak self] event in
            DispatchQueue.main.async {
                self?.handleSessionContextEvent(event)
            }
        }
        
        clientContextObserver = clientContext.eventSignal.addObserver { [weak self] event in
            DispatchQueue.main.async {
                switch event {
                case .licenseStateUpdated(let licensing):
                    self?.notifyMenuState(licensing: licensing)
                default:
                    break
                }
            }
        }
        
        contactInfoStatusObserver = chatManager.contactInfoStatusObservable.addObserver { [weak self] status in
            switch status {
            case .omit:
                self?.pipeline?.notify(event: .inputUpdate(.update(.init(
                    input: .active(
                        placeholder: uiConfig.inputPlaceholder,
                        text: nil,
                        menu: nil
                    ),
                    submit: nil))))
            case .askDesired:
                self?.pipeline?.notify(event: .inputUpdate(.update(.init(
                    input: .active(
                        placeholder: uiConfig.inputPlaceholder,
                        text: nil,
                        menu: nil
                    ),
                    submit: nil))))
            case .askRequired:
                self?.pipeline?.notify(event: .inputUpdate(.update(.init(
                    input: .inactive(
                        reason: loc["chat_input.status.contact_info"]
                    ),
                    submit: nil))))
            case .sent:
                self?.pipeline?.notify(event: .inputUpdate(.update(.init(
                    input: .active(
                        placeholder: uiConfig.inputPlaceholder,
                        text: nil,
                        menu: nil
                    ),
                    submit: nil))))
            }
            
            self?.pipeline?.notify(event: .hasInputUpdates)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        
        managerPipeline.notify(event: .turnInactive(.connection))
        chatManager.hasActiveChat = false
    }
    
    override func run() {
        typingCacheService.cache(text: uiConfig.inputPrefill.jv_valuable)
        
        chatEventObserver = chatManager.eventObservable.addObserver { [weak self] event in
            self?.handleChatEvent(event)
        }
        
        messagingEventObserver = messagingContext.eventObservable.addObserver { [weak self] event in
            self?.handleMessagingEvent(event)
        }

        chatManager.makeAllAgentsOffline()
        chatManager.restoreChat()
        
        managerPipeline.notify(event: .turnActive)
        apnsService.requestForPermission(at: .onAppear)
        
        notifyMenuState(licensing: clientContext.licensing)
    }
    
    /**
     case willAppear
     case textDidChange(text: String)
     case attachmentDidDismiss(index: Int)
     case sendMessage(text: String)
     case messageTap(itemUUID: String, interaction: ChatTimelineTap)
     case mediaTap(url: URL, mime: String?)
     case requestAttachmentMenu(anchor: UIView)
     case requestDeveloperMenu(anchor: UIView)
     case dismiss
     */
    override func handleView(intent: ChatModuleViewIntent) {
        switch intent {
        case .willAppear:
            handleWillAppear()
        case .textDidChange(let text):
            handleTextInput(text: text)
        case .attachmentDidDismiss(let index):
            handleAttachmentDismiss(index: index)
        case .sendMessage(let text):
            handleSendMessageRequest(message: text)
        case .messageTap(let itemUUID, let interaction):
            handleMessageItemDidTap(itemUUID: itemUUID, tapType: interaction)
        case .timelineEvent(.latestPointOfHistory(let visible, let hasData)):
            timelineFirstItemVisibleHandler(isVisible: hasData)
        case .timelineEvent(.exceptionHappened):
            timelineExceptionHandler()
        case .timelineEvent(.middlePointOfHistory(let item)):
            messageGetsVisibleHandler(item: item)
        case .timelineEvent:
            break
        default:
            break
        }
    }
    
    override func handleJoint(input: ChatModuleJointInput) {
        switch input {
        case .performMessageCopy:
            performMessageCopy()
        case .performMessageResend:
            performMessageResend()
        case .pickDocument(let url):
            handleDocument(url: url)
        case .pickImage(let image):
            handleImage(image: image)
        case .requestDeveloperLogs:
            performJournalRequest()
        default:
            break
        }
    }
    
    private func handleWillAppear() {
        let input = typingCacheService.currentInput
        let text = input.text.jv_orEmpty
        pipeline?.notify(event: .inputUpdate(.fill(text: text, attachments: input.attachments)))
        
//        if let placeholder = chatManager.inactivityPlaceholder {
//            pipeline?.notify(event: .inputUpdate(.disable(placeholder: placeholder)))
//        }
        
        notifyReplyingState()
        chatManager.informContactInfoStatus()
        reconnectIfNeeded()
    }
    
    private func handleTextInput(text: String) {
        typingCacheService.cache(text: text.jv_valuable)
        chatManager.sendTyping(text: text)
        notifyReplyingState()
    }
    
    private func reconnectIfNeeded() {
        guard !(networking.isConnected)
        else {
            return
        }
        
        sessionManager.establishConnection()
    }
    
    private func handleImage(image: UIImage) {
        handleMeta(.image(image)) { [weak self] object in
            guard let typingCacheService = self?.typingCacheService
            else {
                return
            }
            
            switch typingCacheService.cache(attachment: object) {
            case .accept:
                self?.pipeline?.notify(event: .inputUpdate(.updateAttachment(object)))
            case .reject:
                break
            case .ignore:
                self?.pipeline?.notify(event: .inputUpdate(.updateAttachment(object)))
            }
            
            self?.notifyReplyingState()
        }
    }
    
    private func performJournalRequest() {
        Jivo.debugging.archiveLogs { [weak self] url, status in
            switch status {
            case .success:
                if let url = url, let data = try? Data(contentsOf: url) {
                    self?.pipeline?.notify(event: .journalReady(url: url, data: data))
                }
                else {
                    self?.pipeline?.notify(event: .warnAbout("Failed to read logs archive"))
                }
                
            case .failedAccessing:
                self?.pipeline?.notify(event: .warnAbout("Failed accessing logs archive"))
                
            case .failedPreparing:
                self?.pipeline?.notify(event: .warnAbout("Failed to prepare logs archive: there may be an encoding error"))
            }
        }
    }
    

    private func handleDocument(url: URL) {
        let object: ChatPhotoPickerObject
        if let image = UIImage(contentsOfFile: url.path) {
            object = ChatPhotoPickerObject(
                uuid: UUID(),
                payload: .image(
                    ChatPhotoPickerImageMeta(
                        image: image,
                        url: url,
                        date: nil,
                        name: url.lastPathComponent.uppercased()
                    )
                )
            )
        }
        else {
            object = ChatPhotoPickerObject(
                uuid: UUID(),
                payload: .file(
                    ChatPhotoPickerFileMeta(
                        url: url,
                        name: url.lastPathComponent,
                        size: url.jv_fileSize ?? 0,
                        duration: 0
                    )
                )
            )
        }
        
        switch typingCacheService.cache(attachment: object) {
        case .accept:
            pipeline?.notify(event: .inputUpdate(.updateAttachment(object)))
        case .reject:
            break
        case .ignore:
            pipeline?.notify(event: .inputUpdate(.updateAttachment(object)))
        }
        
        notifyReplyingState()
    }
    
    private func handleChatEvent(_ event: SdkChatEvent) {
        switch event {
        case .chatObtained(let chat):
            handleChatObtainedEvent(chat: chat)
//        case let .sessionInitialized(isFirstSessionInitialization):
//            handleSessionInitializedEvent(isFirst: isFirstSessionInitialization)
        case .channelAgentsUpdated(let agents):
            handleChannelAgentsUpdated(agents: agents.compactMap(\.resolved))
        case .chatAgentsUpdated(let agents):
            handleChatAgentsUpdated(agents: agents.compactMap(\.resolved))
        case .attachmentsStartedToUpload:
            handleAttachmentsStartedToUploadEvent()
        case .attachmentsUploadSucceded:
            handleAttachmentsUploadSucceededEvent()
        case .mediaUploadFailure(let error):
            handleMediaUploadFailure(withError: error)
        case .exception(let payload):
            handleExceptionEvent(payload)
        case .enableReplying:
            pipeline?.notify(event: .inputUpdate(.update(.init(input: .active(placeholder: uiConfig.inputPlaceholder, text: nil, menu: nil), submit: nil))))
        case .disableReplying(let reason):
            pipeline?.notify(event: .inputUpdate(.update(.init(input: .inactive(reason: reason), submit: nil))))
        default:
            break
        }
    }
    
    private func handleMessagingEvent(_ event: SdkMessagingEvent) {
        switch event {
        case let .messagesUpserted(messagesRefs):
            handleMessagesUpserted(messages: messagesRefs.compactMap(\.resolved))
        case let .messagesRemoved(messagesRefs):
            handleMessagesRemoved(messages: messagesRefs.compactMap(\.resolved))
        case let .messageResend(messageRef):
            handleMessageResending(messageRef)
        case .historyLoaded(let messages):
            handleLocalHistoryLoadedEvent(messages: messages)
        case .allHistoryLoaded:
            handleAllHistoryLoadedEvent()
        case .historyErased:
            handleHistoryErasedEvent()
        case .messageSending:
            break
        }
    }
    
    private func handleChatObtainedEvent(chat: JVDatabaseModelRef<JVChat>) {
        self.chat = chat.resolved
    }
    
    private func handleMessagesUpserted(messages: [JVMessage]) {
        let messagesToUpdate = messages.filter { chatHistory.messages.map(\.UUID).contains($0.UUID) }
        let messagesToPopulate = messages.filter { !chatHistory.messages.map(\.UUID).contains($0.UUID) }
        
        if !messagesToPopulate.isEmpty {
            removeActiveMessage()
            setLoaderHiddenState(to: true)
            messageHistoryRequestTimer?.fire()
        }
        
        messagesToUpdate.forEach { updatingMessage in
            chatHistory.update(message: updatingMessage)
        }
        
        chatHistory.populate(withMessages: messagesToPopulate)
    }
    
    private func handleMessagesRemoved(messages: [JVMessage]) {
        messages.forEach { message in
            chatHistory.remove(message: message)
        }
    }

//    private func appendActiveMessage(isFirstSessionInitialization: Bool) {
//        if let activeMessage = self.uiConfig.helloMessage.jv_valuable {
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
    
    private func removeActiveMessage() {
        if let activeMessage = chatHistory.messages.first(where: { $0.UUID == "activeMessage" }) {
            chatHistory.remove(message: activeMessage)
        }
    }
    
    private func handleMessageResending(_ messageRef: JVDatabaseModelRef<JVMessage>) {
        guard let message = messageRef.resolved
        else {
            return
        }
        
        chatHistory.remove(message: message)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if !(message.status == JVMessageStatus.delivered) {
                self?.chatHistory.update(message: message)
            }
        }
    }
    
//    private func handleSessionInitializedEvent(isFirst isFirstSessionInitialization: Bool) {
//        appendActiveMessage(isFirstSessionInitialization: isFirstSessionInitialization)
//    }
    
    private func handleHistoryErasedEvent() {
        chat = nil
        chatHistory.fill(with: [], partialLoaded: false, unreadPosition: .null)
    }
    
    private func handleLocalHistoryLoadedEvent(messages: [JVDatabaseModelRef<JVMessage>]) {
        let messages = messages.compactMap(\.resolved)
        chatHistory.messages = Array<JVMessage>(messages.reversed())
        chatHistory.fill(with: messages, partialLoaded: false, unreadPosition: .null)
//        chatHistory.populate(withMessages: chatHistory.messages)
    }
    
    private func handleAllHistoryLoadedEvent() {
        allHistoryLoaded = true
        setLoaderHiddenState(to: true)
    }
    
    private func handleAttachmentsStartedToUploadEvent() {
        chatHistory.setBottomItem(
            timelineFactory.generateSystemItem(
                icon: nil,
                meta: systemMessagingService.generateMediaUploading(
                    comment: nil
                ),
                buttons: [],
                countable: false
            )
        )
    }
    
    private func handleAttachmentsUploadSucceededEvent() {
        chatHistory.setBottomItem(nil)
    }
    
    private func handleMediaUploadFailure(withError error: MediaUploadError) {
        chatHistory.setBottomItem(nil)
        typingCacheService.resetInput(context: TypingContext(kind: .chat, ID: chat?.ID ?? 0))
        pipeline?.notify(event: .mediaUploadFailure(error: error))
    }
    
    private func handleChannelAgentsUpdated(agents: [JVAgent]) {
        let channelAgents: [ChatModuleAgent] = agents
            .compactMap {
                guard let agent = jv_validate($0) else { return nil }
                return ChatModuleAgent(
                    id: agent.ID,
                    name: agent.m_display_name.jv_orEmpty,
                    avatarLink: agent.m_avatar_link.jv_orEmpty,
                    status: ChatModuleAgent.Status(agentState: agent.state)
                )
            }
        
        self.channelAgents.upsert(channelAgents) { updatedChannelAgents in
            self.chatHistory.reloadMessages { message in
                if let senderAgentId = message.senderAgent?.ID {
                    return updatedChannelAgents.map(\.id).contains(senderAgentId)
                } else {
                    return false
                }
            }
        }
    }
    
    private func handleChatAgentsUpdated(agents: [JVAgent]) {
        let chatAgents: [ChatModuleAgent] = agents
            .compactMap {
                guard let agent = jv_validate($0) else { return nil }
                return ChatModuleAgent(
                    id: agent.ID,
                    name: agent.m_display_name.jv_orEmpty,
                    avatarLink: agent.m_avatar_link.jv_orEmpty,
                    status: ChatModuleAgent.Status(agentState: agent.state)
                )
            }
        
        self.chatAgents.upsert(chatAgents) { _ in
        }
        
        state.activeAgents = chatAgents.filter { $0.status == .active }
        pipeline?.notify(event: .agentsUpdate)
        
        handleChannelAgentsUpdated(agents: agents)
    }
    
    private func handleExceptionEvent(_ payload: IProtoEventSubjectPayloadAny) {
        journal {"ChatModule exception: \(payload)"}
    }
    
    private func handleSessionContextEvent(_ event: SdkSessionContextEvent) {
        switch event {
        case .networkingStateChanged(.none):
            pipeline?.notify(event: .inputUpdate(.update(.init(input: nil, submit: .connecting))))
        case .networkingStateChanged(_):
            pipeline?.notify(event: .inputUpdate(.update(.init(input: nil, submit: .send))))
        default:
            break
        }
    }
    
    private func notifyMenuState(licensing: SdkClientLicensing?) {
        switch licensing {
        case .licensed:
            state.licenseState = .licensed
            pipeline?.notify(event: .inputUpdate(.update(.init(input: .active(placeholder: nil, text: nil, menu: .active), submit: nil))))
        case .unlicensed:
            state.licenseState = .unlicensed
            pipeline?.notify(event: .inputUpdate(.update(.init(input: .active(placeholder: nil, text: nil, menu: .hidden), submit: nil))))
        case .none:
            state.licenseState = .undefined
            pipeline?.notify(event: .inputUpdate(.update(.init(input: .active(placeholder: nil, text: nil, menu: .hidden), submit: nil))))
        }
        
        pipeline?.notify(event: .licenseUpdate)
    }
    
    var flag = true
    var listeners: [JVDatabaseListener?] = []
    
    private func handleDetachTimelineRequest(timelineView: JMTimelineView<ChatTimelineInteractor>) {
        timelineController.detach(timelineView: timelineView)
    }
    
    private func handleSendMessageRequest(message: String) {
        guard message.count <= SdkConfig.replyLengthLimit
        else {
            return
        }
        
        guard sessionContext.networkingState.hasNetwork
        else {
            return
        }
        
        let attachments = typingCacheService.currentInput.attachments
        guard validateSendingMessageContent(text: message, attachments: attachments) else {
            journal {"Failed validating the message content"}
            return
        }
        
        chatManager.sendMessage(text: message, attachments: attachments)
        reconnectIfNeeded()
        
        if let chat = self.chat {
            typingCacheService.resetInput(context: TypingContext(kind: .chat, ID: chat.ID))
        }
        else {
            assertionFailure()
        }
        
        pipeline?.notify(event: .messageSent)
        pipeline?.notify(event: .inputUpdate(.update(.init(input: .active(placeholder: uiConfig.inputPlaceholder, text: .jv_empty, menu: nil), submit: .send))))
    }
    
    private func validateSendingMessageContent(text: String?, attachments: [ChatPhotoPickerObject]) -> Bool {
        return text?.jv_trimmed().count ?? 0 > 0 || attachments.count > 0
    }
    
    private func handleMessageItemDidTap(itemUUID: String, tapType: ChatTimelineTap) {
        if let message = chatHistory.messages.first(where: { $0.UUID == itemUUID }) {
            selectedMessage = message
            
            let sender: JVSenderType = message.senderClient == nil ? .agent : .client
            state.selectedMessageMeta = (sender, message.delivery)
            pipeline?.notify(event: .messageTapped)
        }
    }
    
    private func handleAttachmentDismissButtonTapRequest(index: Int) {
        typingCacheService.uncache(attachmentAt: index)
    }
    
    private func performMessageCopy() {
        guard let content = selectedMessage?.content
        else {
            return
        }
        
        switch content {
        case let .text(message):
            UIPasteboard.general.string = message
        case let .photo(_, _, link, _, _, _):
            UIPasteboard.general.string = link
        case let .file(_, _, link, _):
            UIPasteboard.general.string = link
        default:
            break
        }
    }
    
    private func performMessageResend() {
        reconnectIfNeeded()
        
        if let uuid = selectedMessage?.UUID {
            chatManager.resendMessage(uuid: uuid)
        }
    }
    
    @objc private func handleAppDidBecomeActive() {
        reconnectIfNeeded()
    }
    
    @objc private func handleAppDidEnterBackground() {
        managerPipeline.notify(event: .turnInactive(.connection))
    }
    
    private func mediaBecameUnavailableHandler(url: URL, mime: String?) {
        pipeline?.notify(event: .remoteMediaUnavailable)
    }
    
    private func handleAttachmentDismiss(index: Int) {
        typingCacheService.uncache(attachmentAt: index)
    }
    
    private func timelineFirstItemVisibleHandler(isVisible: Bool) {
//        let fullAccess = (validate(chat)?.client == nil)
//        let typingAllowance = fullAccess || not(isVisible)
//        pipeline?.notify(event: .typingAllowed(state: typingAllowance))
    }
    
    private func timelineScrollHandler() {
        pipeline?.notify(event: .timelineScrollToBottom)
    }
    
    private func timelineExceptionHandler() {
        pipeline?.notify(event: .timelineRecreate)
    }
    
    private func messageGetsVisibleHandler(item: JMTimelineItem) {
        guard let message = databaseDriver.message(for: item.uid) else {
            return
        }
        
        chatManager.requestMessageHistory(
            fromMessageWithId: message.ID,
            behavior: .actualize)
    }
    
    private func notifyReplyingState() {
        let input = typingCacheService.currentInput
        state.inputText = input.text.jv_orEmpty
        
        pipeline?.notify(event: .inputUpdate(.update(.init(
            input: .active(
                placeholder: uiConfig.inputPlaceholder,
                text: state.inputText,
                menu: nil
            ),
            submit: nil
        ))))
    }
    
    private func handleMeta(_ meta: ChatPickedMeta?, callback: @escaping (ChatPhotoPickerObject) -> Void) {
//        guard let chat = chat, let recipient = chat.recipient else { return }
        let recipient = JVSenderData(type: .agent, ID: 0)
        
        switch meta {
        case .none:
            return
            
        case .asset(let asset)?:
            let uuid = UUID()
            mediaRequestService.request(
                asset: asset,
                recipient: recipient,
                reasonUUID: state.photoRequestReason,
                sizeKind: .export,
                callback: { [callback = callback] response in
                    switch response {
                    case .progress(let progress):
                        callback(
                            ChatPhotoPickerObject(
                                uuid: uuid,
                                payload: .progress(progress)
                            )
                        )
                        
                    case .photo(let image, let url, let date, let name):
                        callback(
                            ChatPhotoPickerObject(
                                uuid: uuid,
                                payload: .image(
                                    ChatPhotoPickerImageMeta(
                                        image: image,
                                        url: url,
                                        date: date,
                                        name: name
                                    )
                                )
                            )
                        )

                    case .video(let url):
                        callback(
                            ChatPhotoPickerObject(
                                uuid: uuid,
                                payload: .file(
                                    ChatPhotoPickerFileMeta(
                                        url: url,
                                        name: url.lastPathComponent,
                                        size: url.jv_fileSize ?? 0,
                                        duration: 0
                                    )
                                )
                            )
                        )
                    }
                }
            )
            
        case .image(let image)?:
            callback(
                ChatPhotoPickerObject(
                    uuid: UUID(),
                    payload: .image(
                        ChatPhotoPickerImageMeta(
                            image: image,
                            url: nil,
                            date: nil,
                            name: nil
                        )
                    )
                )
            )

        case .url(let url)?:
            callback(
                ChatPhotoPickerObject(
                    uuid: UUID(),
                    payload: .file(
                        ChatPhotoPickerFileMeta(
                            url: url,
                            name: url.lastPathComponent,
                            size: url.jv_fileSize ?? 0,
                            duration: 0
                        )
                    )
                )
            )
        }
    }
    
    private func setLoaderHiddenState(to isHidden: Bool) {
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
    }
    
//    private func buildActiveMessage(withText text: String) -> JVMessage {
//        var message: JVMessage!
//
//        databaseDriver.readwrite { context in
//            let entityName = String(describing: JVMessage.self)
//            message = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context.context) as? JVMessage
//            message.m_uid = "activeMessage"
//            message.m_text = text
//            message.m_date = Date()
//            message.m_sender_agent = context.agent(for: -1, provideDefault: true)
//        }
//
//        return message
//    }
}
