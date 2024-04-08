//
//  SdkChatManager.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 15.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import JMCodingKit

import SwiftMime

let MESSAGE_CONTACT_FORM_LOCAL_ID = "MESSAGE_CONTACT_FORM_LOCAL_ID"
fileprivate let notificationPrefix = "jivo:"

extension Notification.Name {
    static let jv_turnContactFormSnapshot = Self.init(rawValue: "jv_turnContactFormSnapshot")
}

enum SdkChatHistoryRequestBehavior {
    case anyway
    case smart
}

enum SdkChatManagerRateFormAction {
    case change(choice: Int, comment: String)
    case submit(scale: ChatTimelineRateScale, choice: Int, comment: String)
    case dismiss
}

enum SdkChatContactFormBehavior {
    case omit
    case blocking
    case regular
}

enum SdkChatManagerError: Error {
    case awaitingContactForm
}

enum SdkChatEvent {
    case sessionInitialized(isFirst: Bool)
    case chatObtained(_ chat: JVDatabaseModelRef<JVChat>)
    case chatAgentsUpdated(_ agents: [JVDatabaseModelRef<JVAgent>])
    case channelAgentsUpdated(_ agents: [JVDatabaseModelRef<JVAgent>])
    case attachmentsStartedToUpload
    case attachmentsUploadSucceded
    case mediaUploadFailure(withError: SdkMediaUploadError)
    case exception(payload: IProtoEventSubjectPayloadAny)
    case enableReplying
    case disableReplying(reason: String)
}

protocol ISdkChatManager: ISdkManager, ChatTimelineFactoryHistoryDelegate {
    var sessionDelegate: JVSessionDelegate? { get set }
    var notificationsDelegate: JVNotificationsDelegate? { get set }
    var eventObservable: JVBroadcastTool<SdkChatEvent> { get }
    var contactInfoStatusObservable: JVBroadcastTool<SdkChatContactInfoStatus> { get }
    var subOffline: ISdkChatSubOffline { get }
    var subHello: ISdkChatSubHello { get }
    var activeSessionHandle: JVSessionHandle? { get set }
    var hasMessagesInQueue: Bool { get }
    var inactivityPlaceholder: String? { get }
    var globalRateConfig: JMTimelineRateConfig?  { get set }
    func restoreChat()
    func makeAllAgentsOffline()
    func sendTyping(text: String)
    func sendMessage(trigger: SdkManagerTrigger, text: String, attachments: [ChatPhotoPickerObject]) throws
    func copy(message: JVMessage)
    func resendMessage(uuid: String)
    func deleteMessage(uuid: String)
    func requestMessageHistory(before anchorMessageId: Int?, behavior: SdkChatHistoryRequestBehavior)
    func markSeen(message: JVMessage)
    
    func identifyContactFormBehavior() -> SdkChatContactFormBehavior
    func informContactInfoStatus()
    func toggleContactForm(message: JVMessage)
    
    func toggleRateForm(message: JVMessage, action: SdkChatManagerRateFormAction)
    
    func handleNotification(_ notification: UNNotification) -> SdkNotificationsEventNature
    func handleNotification(userInfo: [AnyHashable : Any]) -> Bool
    func handleNotification(response: UNNotificationResponse) -> Bool
    func prepareToPresentNotification(_ notification: UNNotification, completionHandler: @escaping JVNotificationsOptionsOutput, resolver: @escaping JVNotificationsOptionsResolver)
}

enum SdkChatContactInfoStatus {
    case omit
    case askRequired
    case askDesired
    case sent
}

enum SdkNotificationsEventNature {
    case nonrelated
    case technical
    case presentable
}

extension RemoteStorageTarget.Purpose {
    static let exchange = RemoteStorageTarget.Purpose(name: "exchange")
}

final class SdkChatManager: SdkManager, ISdkChatManager {
    var sessionDelegate: JVSessionDelegate?
    var notificationsDelegate: JVNotificationsDelegate?
    let contactInfoStatusObservable = JVBroadcastTool<SdkChatContactInfoStatus>()
    
    private enum HistoryLoadingStrategy {
        case keep
        case mostRecent
        case before(messageId: Int)
    }
    
    // MARK: - Constants
    
    let AGENT_DEFAULT_DISPLAY_NAME_LOC_KEY = "agent_name_default"
    
    let subOffline: ISdkChatSubOffline
    let subHello: ISdkChatSubHello
    
    var currentRateFormId: String?
    var globalRateConfig: JMTimelineRateConfig?
    
    // MARK: - Private properties
    
    private var chatMessages: [JVDatabaseModelRef<JVMessage>] = []
    private var isFirstSessionInitialization = true
    private var hasProceedToHistory = false
    private var userDataReceivingMode: AgentDataReceivingMode = .channel {
        didSet {
            subOffline.userDataReceivingMode = userDataReceivingMode
        }
    }
    
    private var historyState = HistoryState()
    private struct HistoryState {
        enum Activity { case initial, requested, synced }
        var activity = Activity.initial
        var requestDate = Date.distantPast
        var localEarliestMessageId: Int?
        var localLatestMessageId: Int?
        var localLatestMessageDate: Date?
        var remoteHasContent = false
        var remoteEarliestMessageId: Int?
        var remoteLatestMessageId: Int?
    }
    
    let eventObservable: JVBroadcastTool<SdkChatEvent>
    
    private let sessionContext: ISdkSessionContext
    private let clientContext: ISdkClientContext
    private let chatContext: ISdkChatContext
    private let messagingContext: ISdkMessagingContext
    private let subStorage: ISdkChatSubStorage
    private let subTyping: ISdkChatSubLivetyping
    private let subSender: ISdkChatSubSender
    private let subUploader: ISdkChatSubUploader
    
    private let typingCacheService: ITypingCacheService
    private let apnsService: ISdkApnsService
    private let preferencesDriver: IPreferencesDriver
    private let keychainDriver: IKeychainDriver
    
    private var applicationState = UIApplication.shared.applicationState
    private var foregroundNotificationOptions = UNNotificationPresentationOptions()
    
    private var outgoingPairedMessagesIds = [String: Array<String>]()
    private var requestedHistoryPastUids = Set<String>()
    private var messagingOutgoingIntents = [OutgoingIntent]()
    
    // MARK: - Init
    
    init(
        pipeline: SdkManagerPipeline,
        thread: JVIDispatchThread,
        sessionContext: ISdkSessionContext,
        clientContext: ISdkClientContext,
        messagingContext: ISdkMessagingContext,
        proto: SdkChatProto,
        eventObservable: JVBroadcastTool<SdkChatEvent>,
        chatContext: ISdkChatContext,
        chatSubStorage: ISdkChatSubStorage,
        subTyping: ISdkChatSubLivetyping,
        chatSubSender: ISdkChatSubSender,
        subUploader: ISdkChatSubUploader,
        subOfflineStateFeature: ISdkChatSubOffline,
        subHelloStateFeature: ISdkChatSubHello,
        systemMessagingService: ISystemMessagingService,
        networkEventDispatcher: INetworkingEventDispatcher,
        typingCacheService: ITypingCacheService,
        apnsService: ISdkApnsService,
        preferencesDriver: IPreferencesDriver,
        keychainDriver: IKeychainDriver
    ) {
        self.sessionContext = sessionContext
        self.clientContext = clientContext
        self.chatContext = chatContext
        self.messagingContext = messagingContext
        self.eventObservable = eventObservable
        self.subStorage = chatSubStorage
        self.subTyping = subTyping
        self.subSender = chatSubSender
        self.subUploader = subUploader
        self.subOffline = subOfflineStateFeature
        self.subHello = subHelloStateFeature

        self.typingCacheService = typingCacheService
        self.apnsService = apnsService
        self.preferencesDriver = preferencesDriver
        self.keychainDriver = keychainDriver
        
        super.init(
            pipeline: pipeline,
            thread: thread,
            userContext: clientContext,
            proto: proto,
            networkEventDispatcher: networkEventDispatcher)
    }
    
    var userContext: ISdkClientContext {
        return userContextAny as! ISdkClientContext
    }
    
    var proto: ISdkChatProto {
        return protoAny as! ISdkChatProto
    }
    
    override func subscribe() {
        super.subscribe()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationWentBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationWentForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTurnContactFormSnapshot),
            name: .jv_turnContactFormSnapshot,
            object: nil)
    }
    
    override func run() -> Bool {
        guard super.run()
        else {
            return false
        }
        
        subStorage.eventSignal.attachObserver { [weak self] in
            self?.handleSubStorageEvent($0)
        }
        
        restoreChatState()
        
        return true
    }
    
    var activeSessionHandle: JVSessionHandle? {
        didSet {
            if activeSessionHandle !== oldValue {
                oldValue?.disableInteraction()
            }
            
            if let _ = activeSessionHandle {
                sendLatestMessageAckIfNeeded()
            }
        }
    }
    
    var hasMessagesInQueue: Bool {
        guard let chatId = sessionContext.localChatId
        else {
            return false
        }
        
        return !subStorage.retrieveQueuedMessages(chatId: chatId).isEmpty
    }
    
    var inactivityPlaceholder: String? {
        guard !preferencesDriver.retrieveAccessor(forToken: .contactInfoWasEverSent).boolean
        else {
            return nil
        }
        
        guard hasMessagesInQueue
        else {
            return nil
        }
        
        return loc["chat_input.status.contact_info"]
    }
    
    private var unreadNumber: Int? = 0 {
        didSet {
            notifyUnreadCounter()
        }
    }
    
    // MARK: - Public methods
    
    func sendTyping(text: String) {
        thread.async { [unowned self] in
            _sendTyping(text: text)
        }
    }
    
    private func _sendTyping(text: String) {
        subTyping.sendTyping(
            clientHash: clientContext.clientHash,
            text: text)
    }
    
    func sendRateForm(id: String, chat: JVChat?) {
        guard let chat = chat else { return }
        
        currentRateFormId = id
        
        let message = subStorage.storeOutgoingMessage(
            localID: UUID().uuidString.lowercased(),
            clientID: userContext.clientHash,
            chatID: chat.ID,
            type: .chatRate,
            content: .rateForm(status: .initial),
            status: nil,
            timing: .regular,
            orderingIndex: 1
        )
        
        if let message = message {
            let messageRef = subStorage.reference(to: message)
            messagingContext.broadcast(event: .messagesUpserted([messageRef]), onQueue: .main)
        }
    }
    
    func sendMessage(trigger: SdkManagerTrigger, text: String, attachments: [ChatPhotoPickerObject]) throws {
        thread.async { [unowned self] in
            _sendMessage(trigger: trigger, text: text, attachments: attachments)
        }
    }
    
    private func _sendMessage(trigger: SdkManagerTrigger, text: String, attachments: [ChatPhotoPickerObject]) {
        journal {"Sending the message"}
        
        DispatchQueue.main.async { [apnsService] in
            apnsService.requestForPermission(at: .onSend)
        }
        
        guard let chat = chatContext.chatRef?.resolved else {
            journal {"Cannot send message: ChatManager.chat doesn't exist"}
            return
        }
        
        switch (historyState.remoteHasContent, trigger) {
        case (true, _), (_, .ui):
            _sendMessage_process(chat: chat, text: text.jv_trimmed())
            _sendMessage_process(attachments: attachments)
        default:
            let intent = OutgoingIntent(text: text)
            messagingOutgoingIntents.append(intent)
        }
    }
    
    private func _sendMessage_process(chat: JVChat, text: String) {
        guard !text.isEmpty
        else {
            journal {"Cannot send message because its text is empty"}
            return
        }
        
        let formBehavior = identifyContactFormBehavior()
        let message = subStorage.storeOutgoingMessage(
            localID: UUID().uuidString.lowercased(),
            clientID: userContext.clientHash,
            chatID: chat.ID,
            type: .message,
            content: .makeWith(text: text),
            status: (formBehavior == .blocking ? .queued : nil),
            timing: (formBehavior == .blocking ? .frozen : .regular),
            orderingIndex: 0)
        
        if let message = message {
            let messageRef = subStorage.reference(to: message)
            messagingContext.broadcast(event: .messageSending(messageRef), onQueue: .main)
            messagingContext.broadcast(event: .messagesUpserted([messageRef]), onQueue: .main)
            
            _sendMessage_removeContactForm(chat: chat)
            _sendMessage_appendContactForm(chat: chat, pairedMessage: message, behavior: formBehavior)
        }
    }
    
    private func _sendMessage_removeContactForm(chat: JVChat) {
        guard let message = subStorage.message(withLocalId: MESSAGE_CONTACT_FORM_LOCAL_ID) else {
            return
        }
        
        guard let pairedIds = outgoingPairedMessagesIds.values.first(where: { $0.contains(message.UUID) }) else {
            return
        }
        
        let pairedMessages = pairedIds.map(subStorage.messageWithUUID)
        subStorage.removeMessages(pairedMessages.jv_flatten())
        
        let pairedMessagesRefs = pairedMessages.map(subStorage.reference(to:))
        messagingContext.broadcast(event: .messagesRemoved(pairedMessagesRefs), onQueue: .main)
    }
    
    private func _sendMessage_appendContactForm(chat: JVChat, pairedMessage: JVMessage, behavior: SdkChatContactFormBehavior) {
        let systemText: String
        switch behavior {
        case .omit:
            return
        case .regular:
            systemText = loc["chat.system.contact_form.introduce_in_chat"]
        case .blocking:
            systemText = loc["chat.system.contact_form.must_fill"]
        }
        
        let systemMessage = subStorage.storeOutgoingMessage(
            localID: UUID().uuidString.lowercased(),
            clientID: userContext.clientHash,
            chatID: chat.ID,
            type: .system,
            content: .makeWith(text: systemText),
            status: .historic,
            timing: .regular,
            orderingIndex: 1)

        if let message = systemMessage {
            let messageRef = subStorage.reference(to: message)
            messagingContext.broadcast(event: .messagesUpserted([messageRef]), onQueue: .main)
        }
        
        let formMessage = subStorage.storeOutgoingMessage(
            localID: MESSAGE_CONTACT_FORM_LOCAL_ID,
            clientID: userContext.clientHash,
            chatID: chat.ID,
            type: .contactForm,
            content: .contactForm(status: .inactive),
            status: nil,
            timing: .regular,
            orderingIndex: 2)

        if let message = formMessage {
            preferencesDriver.retrieveAccessor(forToken: .contactInfoWasShownAt).date = Date()
            
            let messageRef = subStorage.reference(to: message)
            messagingContext.broadcast(event: .messagesUpserted([messageRef]), onQueue: .main)
            
            switch behavior {
            case .omit, .regular:
                break
            case .blocking:
                notifyObservers(event: .disableReplying(reason: loc["chat_input.status.contact_info"]), onQueue: .main)
            }
        }
        
        outgoingPairedMessagesIds[pairedMessage.UUID] = [
            systemMessage?.UUID,
            formMessage?.UUID
        ].jv_flatten()
    }
    
    private func _sendMessage_process(attachments: [ChatPhotoPickerObject]) {
        guard jv_not(attachments.isEmpty)
        else {
            return
        }
        
        guard let clientNumber = userContext.clientNumber,
              let channelId = sessionContext.accountConfig?.channelId,
              let siteId = sessionContext.accountConfig?.siteId
        else {
            journal {"Failed sending the attachments: no credentials found"}
            return
        }
            
        notifyObservers(event: .attachmentsStartedToUpload, onQueue: .main)
        subUploader.upload(attachments: attachments, clientId: clientNumber, channelId: channelId, siteId: siteId) { [weak self] result in
            self?.hanleAttachmentUploading(result: result)
            
            if self?.subUploader.uploadingAttachments.isEmpty ?? false {
                self?.notifyObservers(event: .attachmentsUploadSucceded, onQueue: .main)
            }
        }
    }

    func copy(message: JVMessage) {
        let messageRef = subStorage.reference(to: message)
        thread.async { [unowned self] in
            guard let message = messageRef.resolved else { return }
            _copy(message: message)
        }
    }
    
    private func _copy(message: JVMessage) {
        guard let object = message.obtainObjectToCopy()
        else {
            return
        }
        
        if let url = object as? URL {
            UIPasteboard.general.url = url
        }
        else if let text = object as? String {
            UIPasteboard.general.string = text
        }
    }
    
    func resendMessage(uuid: String) {
        thread.async { [unowned self] in
            _resendMessage(uuid: uuid)
        }
    }
    
    private func _resendMessage(uuid: String) {
        guard let message = subStorage.messageWithUUID(uuid) else {
            journal {"Cannot find a message with UUID[\(uuid)]"}
            return
        }
        subStorage.resendMessage(message)
        
        let messageRef = subStorage.reference(to: message)
        messagingContext.broadcast(event: .messagesUpserted([messageRef]), onQueue: .main)
    }
    
    func deleteMessage(uuid: String) {
        thread.async { [unowned self] in
            _deleteMessage(uuid: uuid)
        }
    }
    
    private func _deleteMessage(uuid: String) {
        guard let message = subStorage.messageWithUUID(uuid) else {
            journal {"Cannot find a message with UUID[\(uuid)]"}
            return
        }
        
        subStorage.deleteMessage(message)
        
        let messageRef = subStorage.reference(to: message)
        messagingContext.broadcast(event: .messagesRemoved([messageRef]), onQueue: .main)
    }
    
    func requestMessageHistory(before anchorMessageId: Int?, behavior: SdkChatHistoryRequestBehavior) {
        thread.async { [unowned self] in
            _requestMessageHistory(before: anchorMessageId, behavior: behavior)
        }
    }
    
    private func _requestMessageHistory(before anchorMessageId: Int?, behavior: SdkChatHistoryRequestBehavior) {
        switch (behavior, historyState.activity, anchorMessageId) {
        case (_, _, 0):
            return
        case (.anyway, _, _):
            break
        case (_, .requested, _):
            return
        case (_, _, _) where Date().timeIntervalSince(historyState.requestDate) < 3.0:
            return
        case (.smart, .synced, .some(historyState.remoteEarliestMessageId)):
            return
        case (.smart, .synced, .some(historyState.localEarliestMessageId)):
            break
        case (.smart, .synced, _):
            return
        case (.smart, .initial, _):
            return
        default:
            return
        }
        
        historyState.activity = .requested
        historyState.requestDate = Date()
        
        switch anchorMessageId {
        case .none:
            journal {"D/LMH REQUEST latest"}
            proto.requestMessageHistory(before: nil)
        case .some(let messageId):
            if let message = subStorage.messageWithID(messageId), message.flags.contains(.edgeToHistoryPast) {
                requestedHistoryPastUids.insert(message.UUID)
                
                let messageRef = subStorage.reference(to: message)
                messagingContext.broadcast(event: .messagesUpserted([messageRef]), onQueue: .main)
            }
            
            journal {"D/LMH REQUEST before \(messageId + 1)"}
            proto.requestMessageHistory(before: messageId + 1)
        }
    }
    
    func markSeen(message: JVMessage) {
        let messageRef = subStorage.reference(to: message)
        thread.async { [unowned self] in
            guard let message = messageRef.resolved else { return }
            _markSeen(message: message)
        }
    }
    
    private func _markSeen(message: JVMessage) {
        proto.sendMessageAck(id: message.ID, date: message.date)
    }
    
    func informContactInfoStatus() {
        thread.async { [unowned self] in
            _informContactInfoStatus()
        }
    }
    
    private func _informContactInfoStatus() {
        contactInfoStatusObservable.broadcast(detectContactInfoStatus(), async: .main)
    }
    
    private func detectContactInfoStatus() -> SdkChatContactInfoStatus {
        guard let chatId = sessionContext.localChatId,
              let lastMessage = subStorage.history(chatId: chatId, after: nil, limit: 1).first
        else {
            return .omit
        }
        
        let accessorForWasEverSent = preferencesDriver.retrieveAccessor(forToken: .contactInfoWasEverSent)
        let accessorForWasShownAt = preferencesDriver.retrieveAccessor(forToken: .contactInfoWasShownAt)
        
        if accessorForWasEverSent.boolean {
            return .sent
        }
        else if accessorForWasShownAt.date == nil {
            return .omit
        }
        
        let channelAgents = chatContext.channelAgents.values.compactMap(\.resolved)
        
        switch userDataReceivingMode {
        case .channel where lastMessage.status == .seen:
            return .askDesired
        case .channel where historyState.remoteHasContent:
            return .askDesired
        case .channel where channelAgents.map(\.state).contains(.active):
            return .askDesired
        case .channel:
            return .askRequired
        case .chat:
            return .askDesired
        }
    }
    
    private func checkRateformStatusChanged(message: JVMessage, newState: JVMessageBodyRateFormStatus) -> Bool {
        let details = message.rawDetails
        let oldState = JsonCoder().decode(raw: details)?.ordictValue["status"]?.stringValue
        
        if oldState == newState.rawValue { return false }
        
        return true
    }
    
    func toggleRateForm(message: JVMessage, action: SdkChatManagerRateFormAction) {
        let messageRef = subStorage.reference(to: message)
        guard let message = messageRef.resolved else { return }
        
        _toggleRateForm(message: message, action: action)
    }
    
    func _toggleRateForm(message: JVMessage, action: SdkChatManagerRateFormAction) {
        let ref = subStorage.reference(to: message)
        
        thread.async { [unowned self] in
            
            switch action {
            case .change(let rate, let comment):
                let details = JsonCoder().encodeToRaw([
                    "status": JVMessageBodyRateFormStatus.rated.rawValue,
                    "last_rate": String(rate),
                    "last_comment": comment
                ]).jv_orEmpty
                
                
                if checkRateformStatusChanged(message: message, newState: JVMessageBodyRateFormStatus.rated) {
                    subStorage.turnRateForm(
                        message: message,
                        details: details
                    )
                    DispatchQueue.main.async { [unowned self] in
                        messagingContext.broadcast(event: .messagesUpserted([ref]))
                    }
                } else {
                    subStorage.turnRateForm(
                        message: message,
                        details: details
                    )
                }
            case .submit(let scale, let choice, let comment):
                let details = JsonCoder().encodeToRaw([
                    "status": JVMessageBodyRateFormStatus.sent.rawValue,
                    "last_rate": String(choice),
                    "last_comment": comment
                ]).jv_orEmpty
                
                subStorage.turnRateForm(
                    message: message,
                    details: details
                )
                
                DispatchQueue.main.async { [unowned self] in
                    messagingContext.broadcast(event: .messagesUpserted([ref]))
                }
                
                guard let currentRateFormId = currentRateFormId else { return }
                
                proto.sendRateInfo(
                    chatID: currentRateFormId,
                    rate: scale.aliases[choice],
                    comment: comment
                )
            case .dismiss:
                let details = JsonCoder().encodeToRaw([
                    "status": JVMessageBodyRateFormStatus.dismissed.rawValue
                ]).jv_orEmpty
                
                subStorage.turnRateForm(
                    message: message,
                    details: details
                )
                
                DispatchQueue.main.async { [unowned self] in
                    messagingContext.broadcast(event: .messagesUpserted([ref]))
                }
            }
        }
    }
    
    func toggleContactForm(message: JVMessage) {
        let messageRef = subStorage.reference(to: message)
        thread.async { [unowned self] in
            guard let message = messageRef.resolved else { return }
            _toggleContactForm(message: message)
        }
    }
    
    private func _toggleContactForm(message: JVMessage) {
        subStorage.turnContactForm(
            message: message,
            status: .editable,
            details: nil)
        
        let messageRef = subStorage.reference(to: message)
        DispatchQueue.main.async { [unowned self] in
            subStorage.refresh()
            guard let message = messageRef.resolved else { return }
            let ref = subStorage.reference(to: message)
            messagingContext.broadcast(event: .messagesUpserted([ref]))
        }
    }
    
    func handleNotification(_ notification: UNNotification) -> SdkNotificationsEventNature {
        if notification.request.identifier.hasPrefix(notificationPrefix) {
            return .presentable
        }
        
        let parsingResult = parseRemoteNotification(containingUserInfo: notification.extractUserInfo())
        guard case .success(let model) = parsingResult else {
            return .nonrelated
        }
        
        switch model {
        case .message(let sender, let text):
            handlePushMessage(
                notification: notification,
                userInfo: notification.extractUserInfo(),
                sender: sender,
                text: text)
        case .other:
            break
        }
        
        return .technical
    }
    
    func handleNotification(userInfo: [AnyHashable : Any]) -> Bool {
        switch parseRemoteNotification(containingUserInfo: userInfo) {
        case let .success(notification):
            historyState.remoteLatestMessageId = (activeSessionHandle.jv_hasValue ? nil : .max)
            notificationDidTap(notification)
            return true
        case .failure:
            return false
        }
    }
    
    func handleNotification(response: UNNotificationResponse) -> Bool {
        switch parseNotification(response.notification) {
        case .success(let notification):
            notificationDidTap(notification)
            return true
        case .failure:
            return false
        }
    }
    
    func prepareToPresentNotification(_ notification: UNNotification, completionHandler: @escaping JVNotificationsOptionsOutput, resolver: @escaping JVNotificationsOptionsResolver) {
        if notification.request.identifier.hasPrefix(notificationPrefix) {
            completionHandler(resolver(.sdk, .any))
            return
        }
        
        guard case .success(let model) = parseRemoteNotification(containingUserInfo: notification.extractUserInfo())
        else {
            completionHandler(resolver(.app, .any))
            return
        }
        
        switch model {
        case .message(let sender, let text):
            handlePushMessage(
                notification: notification,
                userInfo: notification.extractUserInfo(),
                sender: sender,
                text: text)
        case .other:
            break
        }
        
        completionHandler(.jv_empty)
    }
    
    private func handlePushMessage(notification: UNNotification?, userInfo: [AnyHashable: Any], sender: String, text: String) {
        switch (userInfo["message_id"] as? Int, historyState.remoteLatestMessageId) {
        case (.none, _) where unreadNumber == nil:
            // Do nothing if chat is opened
            break
        case (.none, _):
            requestRecentActivity()
        case (.some(let messageId), .some(let remoteId)) where messageId <= remoteId:
            // Do nothing if message_id is older than another that we have
            break
        case (.some(let messageId), _):
            historyState.remoteLatestMessageId = messageId
            unreadNumber? = 1
        }
        
        let content: UNMutableNotificationContent
        if let object = notification?.request.content.copy() as? UNMutableNotificationContent {
            content = object
        }
        else {
            content = UNMutableNotificationContent()
            content.subtitle = sender
            content.body = text
            content.userInfo = userInfo
        }
        
        if let delegate = notificationsDelegate {
            if let result = delegate.jivoNotifications(prepareBanner: .shared, content: content, sender: sender, text: text) {
                UNUserNotificationCenter.current().add(UNNotificationRequest(
                    identifier: notificationPrefix + UUID().uuidString,
                    content: result,
                    trigger: nil
                ))
            }
        }
        else {
            UNUserNotificationCenter.current().add(UNNotificationRequest(
                identifier: notificationPrefix + UUID().uuidString,
                content: content,
                trigger: nil
            ))
        }
    }
    
    func restoreChat() {
        restoreChatState()
    }
    
    func makeAllAgentsOffline() {
        thread.async { [unowned self] in
            _makeAllAgentsOffline()
        }
    }
    
    func requestRecentActivity() {
        thread.async { [unowned self] in
            _requestRecentActivity()
        }
    }
    
    private func _requestRecentActivity() {
        guard let accountConfig = sessionContext.accountConfig,
              accountConfig.siteId > .zero,
              let clientId = clientContext.clientId,
              let _ = sessionContext.localChatId
        else {
            return
        }
        
        proto
            .requestRecentActivity(
                siteId: accountConfig.siteId,
                channelId: accountConfig.channelId,
                clientId: clientId)
            .silent()
    }
    
    private func _makeAllAgentsOffline() {
        subStorage.makeAllAgentsOffline()
    }
    
    // MARK: BaseManager methods
    
    public override func handleProtoEvent(subject: IProtoEventSubject, context: ProtoEventContext?) {
        switch subject as? SdkSessionProtoEventSubject {
        case .connectionConfig(let meta):
            handleConnectionConfig(meta: meta, context: context)
        case .socketOpen:
            handleSocketOpened()
        case let .socketClose(kind, error):
            handleSocketClosed(kind: kind, error: error)
        default:
            break
        }
        
        switch subject as? SdkChatProtoEventSubject {
        case .recentActivity(let meta):
            handleRecentMessages(meta: meta)
        default:
            break
        }
    }
    
    public override func handleProtoEvent(transaction: [NetworkingEventBundle]) {
        let userTransaction = transaction.filter { $0.payload.type == .chat(.user) }
        handleUserTransaction(userTransaction)
        
        let meTransaction = transaction.filter { $0.payload.type == .session(.me) }
        handleMeTransaction(meTransaction)
        
        let messageTransaction = transaction.filter { $0.payload.type == .chat(.message) }
        handleMessageTransaction(messageTransaction)
        
        _informContactInfoStatus()
    }
    
    override func _handlePipeline(event: SdkManagerPipelineEvent) {
        switch event {
        case .turnActive:
            _handlePipelineTurnActiveEvent()
        case .turnInactive(let subsystems):
            _handlePipelineTurnInactiveEvent(subsystems: subsystems)
        }
    }
    
    private func _handlePipelineTurnActiveEvent() {
        unreadNumber = nil
    }

    private func _handlePipelineTurnInactiveEvent(subsystems: SdkManagerSubsystem) {
        if subsystems.contains(.connection) {
            subOffline.reactToInactiveConnection()
            subHello.reactToInactiveConnection()
            unreadNumber = 0
        }
        
        if subsystems.contains(.artifacts) {
            isFirstSessionInitialization = true
            hasProceedToHistory = false
            userDataReceivingMode = .channel
            chatContext.chatAgents = [:]
            chatContext.channelAgents = [:]
            chatMessages = []
            historyState = HistoryState()
            messagingContext.broadcast(event: .historyErased, onQueue: .main)
            notifyObservers(event: .chatAgentsUpdated(.jv_empty), onQueue: .main)
            typingCacheService.resetInput(context: TypingContext(kind: .chat, ID: chatContext.chatRef?.resolved?.ID ?? 0))
            chatContext.chatRef = nil
            subStorage.deleteAllMessages()
            outgoingPairedMessagesIds.removeAll()
            requestedHistoryPastUids.removeAll()
            preferencesDriver.retrieveAccessor(forToken: .contactInfoWasShownAt).erase()
            preferencesDriver.retrieveAccessor(forToken: .contactInfoWasEverSent).erase()
            unreadNumber = 0
            messagingOutgoingIntents.removeAll()
        }
    }

    private func handleMeTransaction(_ transaction: [NetworkingEventBundle]) {
        transaction.forEach { bundle in
            switch bundle.payload.subject {
            case SdkSessionProtoMeSubject.id:
                historyState.remoteHasContent = true
            case SdkSessionProtoMeSubject.history(.some(let messageId)):
                historyState.remoteHasContent = true
                historyState.remoteLatestMessageId = messageId
                notifyUnreadCounter()
            case SdkSessionProtoMeSubject.history(.none):
                historyState.remoteEarliestMessageId = historyState.localEarliestMessageId
                historyState.activity = .synced
                handleMeTransaction_contactFormAutorun()
                messagingContext.broadcast(event: .allHistoryLoaded, onQueue: .main)
            default:
                break
            }
        }
        
        _flushSilentMessages()
    }
    
    private func handleMeTransaction_contactFormAutorun() {
        informContactInfoStatus()
        
        switch detectContactInfoStatus() {
        case .askRequired:
            break
        case .omit, .askDesired, .sent:
            flushQueuedMessages()
        }
    }
    
    private func handleMessageTransaction(_ transaction: [NetworkingEventBundle]) {
        guard let chat = self.chatContext.chatRef?.resolved else {
            return
        }
        
        historyState.activity = .synced
        
        let inmemoryFirstId = historyState.localEarliestMessageId ?? .min
        let inmemoryLastId = historyState.localLatestMessageId ?? .max
        let persistentIds = Set(subStorage.historyIdsBetween(chatId: chat.ID, firstId: inmemoryFirstId, lastId: inmemoryLastId))
        var shouldSendMessageAck = false
        
        var upsertedMessages = OrderedMap<String, JVMessage>()
        transaction.forEach { bundle in
            guard let subject = bundle.payload.subject as? SdkChatProtoMessageSubject else {
                return
            }
            
            switch subject {
            case .delivered(let messageId, _, let messageDate), .received(let messageId, _, _, _, let messageDate):
                defer {
                    historyState.remoteHasContent = true
                    historyState.localEarliestMessageId.jv_replaceWithLesser(messageId)
                    historyState.localLatestMessageId.jv_replaceWithGreater(messageId)
                    historyState.localLatestMessageDate.jv_replaceWithGreater(messageDate)
                }

                guard let message: JVMessage = {
                    switch bundle.payload.id {
                    case let id as String:
                        return subStorage.upsertMessage(byPrivateId: id, inChatWithId: chat.ID, with: [subject])

                    case let id as Int:
                        let message = subStorage.upsertMessage(
                            havingId: id,
                            inChatWithId: chat.ID,
                            with: [subject])
                        
                        if let lastSeenMessageId = keychainDriver.retrieveAccessor(forToken: .lastSeenMessageId, usingClientToken: true).number,
                           lastSeenMessageId == id {
                            let seenMessages = markMessagesAsSeen(to: id)
                            seenMessages.forEach {
                                upsertedMessages[$0.UUID] = $0
                            }
                        }

                        return message

                    default:
                        return nil
                    }
                }() else { return }
                
                upsertedMessages[message.UUID] = message
                
                if let linkedMessageIds = outgoingPairedMessagesIds.removeValue(forKey: message.UUID) {
                    do {
                        for linkedMessage in linkedMessageIds.compactMap(subStorage.messageWithUUID) {
                            _ = subStorage.updateMessage(change: try JVSdkMessageAtomChange(
                                localId: linkedMessage.localID,
                                updates: [
                                    .date(message.anchorDate)
                                ]
                            ))
                        }
                    }
                    catch {
                    }
                }
                
            case let .seen(id, _): // second associated value is date
                historyState.remoteHasContent = true
                
                let seenMessages = markMessagesAsSeen(to: id)
                seenMessages.forEach { upsertedMessages[$0.UUID] = $0 }
            case .rate:
                guard let rateFormID = bundle.payload.id as? String else {
                    assertionFailure()
                    return
                }
                sendRateForm(id: rateFormID, chat: self.chatContext.chatRef?.resolved)
            }
            
            switch subject {
            case .received(let messageId, _, _, _, let sentAt) where messageId > historyState.localLatestMessageId.jv_orZero:
                historyState.localLatestMessageId = messageId
                historyState.localLatestMessageDate = sentAt
                shouldSendMessageAck = activeSessionHandle.jv_hasValue

            default:
                break
            }
        }
        
        handleMessageTransaction_detectMissingRanges(
            incomingMessages: upsertedMessages.map(\.value).sorted { $0.date < $1.date },
            persistentIds: persistentIds,
            inmemoryRange: (inmemoryFirstId ... inmemoryLastId))
        
        requestedHistoryPastUids.subtract(upsertedMessages.orderedKeys)
        
        if shouldSendMessageAck {
            sendLatestMessageAckIfNeeded()
        }
        
        let messageReferences = subStorage.reference(to: Array(upsertedMessages.orderedValues.filter(\.hasBeenChanged)))
        messagingContext.broadcast(event: .messagesUpserted(messageReferences), onQueue: .main)
        
        notifyUnreadCounter()
        _flushSilentMessages()
    }
    
    private func handleMessageTransaction_detectMissingRanges(
        incomingMessages: [JVMessage],
        persistentIds: Set<Int>,
        inmemoryRange: ClosedRange<Int>
    ) {
        let incomingIds = Set(incomingMessages.map(\.ID))
        let guaranteedPersistentIds = persistentIds.sorted().dropFirst()
        
        guard let firstIncomingId = incomingIds.first else {
            return
        }
        
        let chain = journal {"D/LMH RESPONSE"}
        chain.journal {"D/LMH network[\(incomingIds.min().jv_orZero)...\(incomingIds.max().jv_orZero)]"}
        chain.journal {"D/LMH inmemory[\(inmemoryRange)]"}
        chain.journal {"D/LMH persistent[\(persistentIds.min().jv_orZero)...\(persistentIds.max().jv_orZero)]"}

        let conjointIds: Set<Int>
        let edgeMessage: JVMessage?
        
        if let latestPersistentId = guaranteedPersistentIds.last {
            if incomingIds.isSubset(of: guaranteedPersistentIds) {
                chain.journal {"D/LMH received a slice of internal history"}
                conjointIds = incomingIds
                edgeMessage = nil
            }
            else if incomingIds == [firstIncomingId] {
                chain.journal {"D/LMH received a single new message"}
                conjointIds = incomingIds
                edgeMessage = nil
            }
            else if incomingIds.max().jv_orZero == persistentIds.min().jv_orZero {
                chain.journal {"D/LMH received a slice of separate older history"}
                conjointIds = incomingIds
                edgeMessage = nil
            }
            else if incomingIds.isDisjoint(with: [latestPersistentId, latestPersistentId + 1]) {
                chain.journal {"D/LMH received a slice of separate newer history"}
                conjointIds = incomingIds
                edgeMessage = incomingMessages.first
            }
            else {
                chain.journal {"D/LMH received a slice of conjoint newer history"}
                conjointIds = incomingIds.union(persistentIds)
                edgeMessage = nil
            }
        }
        else {
            chain.journal {"D/LMH received a slice of standalone history"}
            conjointIds = incomingIds
            edgeMessage = nil
        }

        subStorage.resetHistoryPointers(
            flag: .edgeToHistoryPast,
            amongIds: Array(conjointIds.sorted().dropFirst()))
        
        if let edgeMessage = edgeMessage {
            subStorage.placeHistoryPointer(
                flag: .edgeToHistoryPast,
                to: edgeMessage)
        }
    }
    
    private func markMessagesAsSeen(to messageId: Int) -> [JVMessage] {
        keychainDriver.retrieveAccessor(forToken: .lastSeenMessageId, usingClientToken: true).number = Int(messageId)
        
        guard let chatId = self.chatContext.chatRef?.resolved?.ID else { return [] }
        let seenClientMessages = subStorage
            .markMessagesAsSeen(to: messageId, inChatWithId: chatId)
            .filter { !$0.m_is_incoming }
        
        return seenClientMessages
    }
    
    private func handleUserTransaction(_ transaction: [NetworkingEventBundle]) {
        let hasChanges: Bool = transaction.reduce(false) { hasChangesRef, bundle in
            guard let subject = bundle.payload.subject as? SdkChatProtoUserSubject else {
                return hasChangesRef
            }
            
            let agentId = bundle.payload.id.flatMap(String.init).flatMap(Int.init) ?? .zero
            let agent = (agentId == .zero ? nil : subStorage.upsertAgent(havingId: agentId, with: [subject]))
            
            switch (subject, agent, userDataReceivingMode) {
            case (.switchingDataReceivingMode, _, _):
                userDataReceivingMode = .chat
                return true
            case (_, .none, _):
                break
            case (_, .some(let agent), .channel):
                chatContext.channelAgents[agentId] = subStorage.reference(to: agent)
                return (hasChangesRef || agent.hasBeenChanged)
            case (_, .some(let agent), .chat):
                chatContext.chatAgents[agentId] = subStorage.reference(to: agent)
                return (hasChangesRef || agent.hasBeenChanged)
            }
            
            return hasChangesRef
        }
        
        guard hasChanges else {
            return
        }
        
        let chatAgents = chatContext.chatAgents.values.compactMap(\.resolved)
        storeChatAgents(chatAgents, exclusive: false)

        switch userDataReceivingMode {
        case .channel:
            DispatchQueue.main.async { [unowned self] in
                subStorage.refresh()
                notifyObservers(event: .channelAgentsUpdated(Array(chatContext.channelAgents.values)))
            }
            
        case .chat:
            guard jv_not(chatContext.chatAgents.isEmpty) else {
                break
            }
            
            DispatchQueue.main.async { [unowned self] in
                subStorage.refresh()
                notifyObservers(event: .chatAgentsUpdated(Array(chatContext.chatAgents.values)))
            }
        }
    }
    
    private func manageContactFormAndQueuedMessage() {
        guard userDataReceivingMode == .channel
        else {
            return
        }
        
        guard preferencesDriver.retrieveAccessor(forToken: .contactInfoWasShownAt).hasObject
        else {
            return
        }
        
        let states = chatContext.channelAgents.values.compactMap(\.resolved).map(\.state)
        if states.contains(.active) {
            flushQueuedMessages()
        }
        else if let reason = inactivityPlaceholder {
            DispatchQueue.main.async { [weak self] in
                self?.notifyObservers(event: .disableReplying(reason: reason), onQueue: .main)
            }
        }
    }
    
    private func handleConnectionConfig(meta: ProtoEventSubjectPayload.ConnectionConfig, context: ProtoEventContext?) {
        globalRateConfig = meta.body.rateConfig
        _requestRecentActivity()
    }
    
    private func handleSocketOpened() {
        userDataReceivingMode = .channel
        chatContext.channelAgents = [:]
        chatContext.chatAgents = [:]
        storeChatAgents([], exclusive: true)
        
        _requestMessageHistory(before: nil, behavior: .anyway)
        
        notifyObservers(event: .sessionInitialized(isFirst: isFirstSessionInitialization.getAndDisable()), onQueue: .main)
        notifyObservers(event: .channelAgentsUpdated(.jv_empty), onQueue: .main)
        notifyObservers(event: .chatAgentsUpdated(.jv_empty), onQueue: .main)
        
        subOffline.reactToActiveConnection()
        subHello.reactToActiveConnection()
        subSender.reactToActiveConnection()
    }
    
    private func handleSocketClosed(kind: APIConnectionCloseCode, error: Error?) {
        historyState.remoteHasContent = false
        userDataReceivingMode = .channel
        
        subOffline.reactToInactiveConnection()
        subHello.reactToInactiveConnection()
        subSender.reactToInactiveConnection()
    }
    
    private func handleRecentMessages(meta: ProtoEventSubjectPayload.RecentActivity) {
        historyState.remoteLatestMessageId = meta.body.latestMessageId
        notifyUnreadCounter()
    }
    
    // MARK: SubStorage event handling methods
    
    private func handleSubStorageEvent(_ event: SdkChatSubStorageEvent) {
        switch event {
        case .messageSendingFailure(let message):
            let messageRef = subStorage.reference(to: message)
            messagingContext.broadcast(event: .messagesUpserted([messageRef]), onQueue: .main)
            
        case .messageResending(let message):
            let messageRef = subStorage.reference(to: message)
            messagingContext.broadcast(event: .messageResend(messageRef), onQueue: .main)
        }
    }
    
    // MARK: SubUploader event handling methods
    private func hanleAttachmentUploading(result: Result<JVMessageContent, ChatMediaUploadingError>) {
        switch result {
        case let .success(attachment):
            guard
                let chat = self.chatContext.chatRef?.resolved,
                let message = self.subStorage.storeOutgoingMessage(
                    localID: UUID().uuidString.lowercased(),
                    clientID: self.userContext.clientHash,
                    chatID: chat.ID,
                    type: .message,
                    content: attachment,
                    status: nil,
                    timing: .regular,
                    orderingIndex: 0)
            else {
                journal {"Failed sending the message with media"}
                return notifyObservers(event: .mediaUploadFailure(withError: .cannotHandleUploadResult), onQueue: .main)
            }
            
            let messageRef = subStorage.reference(to: message)
            messagingContext.broadcast(event: .messagesUpserted([messageRef]), onQueue: .main)
            
        case let .failure(error):
            switch error {
            case .cannotExtractData:
                notifyObservers(event: .mediaUploadFailure(withError: .extractionFailed), onQueue: .main)
                
            case .networkClientError:
                notifyObservers(event: .mediaUploadFailure(withError: .networkClientError), onQueue: .main)
                
            case let .sizeLimitExceeded(megabytes):
                notifyObservers(event: .mediaUploadFailure(withError: .fileSizeExceeded(megabytes: megabytes)), onQueue: .main)
                
            case .cannotHandleUploadResult:
                notifyObservers(event: .mediaUploadFailure(withError: .cannotHandleUploadResult), onQueue: .main)
                
            case let .uploadDeniedByAServer(errorDescription):
                notifyObservers(event: .mediaUploadFailure(withError: .uploadDeniedByAServer(errorDescription: errorDescription)), onQueue: .main)
                
            case .unsupportedMediaType:
                notifyObservers(event: .mediaUploadFailure(withError: .unsupportedMediaType), onQueue: .main)
                
            case let .unknown(errorDescription):
                notifyObservers(event: .mediaUploadFailure(withError: .unknown(errorDescription: errorDescription)), onQueue: .main)
            }
        }
    }
    
    // MARK: Other private methods
    
    private func notifyObservers(event: SdkChatEvent) {
        eventObservable.broadcast(event)
    }
    
    private func notifyObservers(event: SdkChatEvent, onQueue queue: DispatchQueue) {
        eventObservable.broadcast(event, async: queue)
    }
    
    private func restoreChatState() {
        thread.async { [unowned self] in
            if let chat = obtainChat() {
                let chatID = chat.ID
                let history = subStorage.history(chatId: chat.ID, after: nil, limit: 30)
                journal {"Chat: found and activate\nchat-id[\(chatID)]"}
                
                chatContext.chatRef = subStorage.reference(to: chat)
                chatMessages = subStorage.reference(to: history)
                
                let messagesIds = history.map(\.ID).filter { $0 > .zero }
                historyState.activity = .synced
                historyState.localEarliestMessageId = messagesIds.min()
                historyState.localLatestMessageId = messagesIds.max()
                historyState.localLatestMessageDate = history.last?.date

                messagingContext.broadcast(event: .historyLoaded(history: chatMessages), onQueue: .main)
                notifyObservers(event: .chatObtained(subStorage.reference(to: chat)), onQueue: .main)
                
                chat.agents.forEach { agent in
                    chatContext.chatAgents[agent.ID] = subStorage.reference(to: agent)
                }
                
                let agentsRefs = chat.agents.map { subStorage.reference(to: $0) }
                notifyObservers(event: .chatAgentsUpdated(agentsRefs), onQueue: .main)
            }
        }
    }
    
    private func obtainChat() -> JVChat? {
        guard let crc32EncryptedClientToken = sessionContext.localChatId else {
            journal {"Failed obtaining a chat because clientToken doesn't exists"}
            return nil
        }
        
        if let chat = self.chatContext.chatRef?.resolved { return chat }
        if let chat = subStorage.chatWithID(crc32EncryptedClientToken) { return chat }
        if let chat = subStorage.createChat(withChatID: crc32EncryptedClientToken) {
            return chat
        } else {
            journal {"Failed creating a chat: something went wrong"}
            return nil
        }
    }
    
    private func storeChatAgents(_ agents: [JVAgent], exclusive: Bool) {
        guard let chat = obtainChat() else {
            journal {"Failed obtaining a chat: something went wrong"}
            return
        }
        let chatChange = JVSdkChatAgentsUpdateChange(id: chat.ID, agentIds: agents.map(\.ID), exclusive: exclusive)
        guard let _ = subStorage.storeChat(change: chatChange) else {
            journal {"Failed updating the chat: something went wrong"}
            return
        }
    }
    
    enum CalculatingOutgoingStatusError: Error {
        case hasMessagesInQueue
    }
    
    func identifyContactFormBehavior() -> SdkChatContactFormBehavior {
        guard let chat = chatContext.chatRef?.resolved else {
            return .omit
        }
            
        guard not(preferencesDriver.retrieveAccessor(forToken: .contactInfoWasEverSent).boolean) else {
            return .omit
        }
        
        let agents = chatContext.channelAgents.values.compactMap(\.resolved)
        let states = agents.map(\.state)
        
        switch userDataReceivingMode {
        case .channel where preferencesDriver.retrieveAccessor(forToken: .contactInfoWasShownAt).hasObject:
            return .omit
        case .channel where states.contains(.active):
            return .regular
        case .channel:
            return .blocking
        case .chat:
            return .omit
        }
    }
    
    private func notificationDidTap(_ sender: SdkClientSubPusherNotification) {
        switch sender {
        case .message where jv_not(Jivo.display.isOnscreen):
            Jivo.display.delegate?.jivoDisplay(asksToAppear: .shared)
        default:
            break
        }
    }
    
    @objc private func handleApplicationWentBackground() {
        DispatchQueue.main.async { [unowned self] in
            applicationState = UIApplication.shared.applicationState
        }
    }
    
    @objc private func handleApplicationWentForeground() {
        requestRecentActivity()
        
        DispatchQueue.main.async { [unowned self] in
            applicationState = UIApplication.shared.applicationState
        }
    }
    
    @objc private func handleTurnContactFormSnapshot(notification: Notification) {
        if let info = notification.object as? JVSessionContactInfo {
            flushContactForm(info: info)
        }
        
        flushQueuedMessages()
        
        DispatchQueue.main.async {
            self.notifyObservers(event: .enableReplying)
        }
    }
    
    private func sendLatestMessageAckIfNeeded() {
        guard let messageId = historyState.localLatestMessageId else {
            return
        }
        
        guard let date = historyState.localLatestMessageDate else {
            return
        }
        
        proto
            .sendMessageAck(id: messageId, date: date)
    }
    
    private func flushContactForm(info: JVSessionContactInfo) {
        guard let _ = obtainChat()?.ID
        else {
            return
        }
        
        let message = subStorage.message(withLocalId: MESSAGE_CONTACT_FORM_LOCAL_ID)
        let messageRef = subStorage.reference(to: message)
        thread.async { [unowned self] in
            guard let message = messageRef.resolved else { return }
            
            subStorage.turnContactForm(
                message: message,
                status: .snapshot,
                details: [
                    "name": info.name ?? String(),
                    "phone": info.phone ?? String(),
                    "email": info.email ?? String()
                ])
            
            DispatchQueue.main.async { [unowned self] in
                subStorage.refresh()
                messagingContext.broadcast(event: .messagesUpserted([messageRef]))
            }
        }
    }
    
    private func _flushSilentMessages() {
        guard messagingOutgoingIntents.jv_hasElements else {
            return
        }
        
        guard historyState.remoteHasContent else {
            return
        }
        
        let intents = messagingOutgoingIntents
        messagingOutgoingIntents.removeAll()

        for intent in intents {
            _sendMessage(
                trigger: .api,
                text: intent.text,
                attachments: .jv_empty)
        }
    }
    
    private func flushQueuedMessages() {
        guard let chatId = obtainChat()?.ID
        else {
            return
        }
        
        thread.async { [unowned self] in
            let queuedMessages = subStorage.retrieveQueuedMessages(chatId: chatId)
            guard jv_not(queuedMessages.isEmpty)
            else {
                return
            }
            
            for message in queuedMessages {
                subStorage.resendMessage(message)
            }
            
            let systemMessageRef = subStorage.reference(
                to: subStorage.storeOutgoingMessage(
                    localID: UUID().uuidString.lowercased(),
                    clientID: userContext.clientHash,
                    chatID: chatId,
                    type: .system,
                    content: .text(message: loc["chat.system.contact_form.status_sent"]),
                    status: nil,
                    timing: .regular,
                    orderingIndex: 0))
            
            DispatchQueue.main.async { [unowned self] in
                subStorage.refresh()
                messagingContext.broadcast(event: .messagesUpserted([systemMessageRef]))
            }
        }
    }
    
    func parseRemoteNotification(containingUserInfo userInfo: [AnyHashable : Any]) -> Result<SdkClientSubPusherNotification, SdkClientSubPusherNotificationParsingError> {
        guard userInfo.keys.contains("jivosdk") else {
            return .failure(.notificationSenderIsNotJivo)
        }
        
        let root = JsonElement(userInfo)
        let alert = root["aps"]["alert"]
        let args = alert["loc-args"]
        
        switch alert["loc-key"].stringValue {
        case "JV_MESSAGE":
            let sender = args.arrayValue.prefix(1).last?.string ?? String()
            let text = args.arrayValue.prefix(2).last?.string ?? String()
            return .success(.message(sender: sender, text: text))
        default:
            return .success(.other)
        }
    }
    
    func parseNotification(_ notification: UNNotification) -> Result<SdkClientSubPusherNotification, SdkClientSubPusherNotificationParsingError> {
        return parseRemoteNotification(containingUserInfo: notification.extractUserInfo())
    }
    
    private func notifyUnreadCounter() {
        guard let delegate = sessionDelegate else {
            return
        }
        
        func _notify(number: Int) {
            DispatchQueue.main.async {
                delegate.jivoSession(updateUnreadCounter: .shared, number: number)
            }
        }
        
        guard let chatId = sessionContext.localChatId else {
            _notify(number: 0)
            return
        }
        
        switch (subStorage.lastSyncedMessage(chatId: chatId)?.ID, historyState.remoteLatestMessageId) {
        case (.none, .none):
            _notify(number: 0)
        case (.none, .some):
            _notify(number: 1)
        case (.some, .none):
            _notify(number: 0)
        case (.some(let localId), .some(let knownId)):
            _notify(number: localId < knownId ? 1 : 0)
        }
    }
    
    func timelineFactory(isLoadingHistoryPast messageUid: String) -> Bool {
        return requestedHistoryPastUids.contains(messageUid)
    }
    
    func timelineFactory(isLoadingHistoryFuture messageUid: String) -> Bool {
        return false
    }
}

enum AgentDataReceivingMode {
    case channel
    case chat
}

private struct OutgoingIntent {
    let text: String
}

fileprivate extension UNNotification {
    func extractUserInfo() -> [AnyHashable: Any] {
        return request.content.userInfo
    }
}
