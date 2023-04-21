//
//  ChatSubOfflineStateFlow.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 17.03.2022.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

protocol ISdkChatSubOffline: AnyObject {
    var customText: String? { get set }
    var userDataReceivingMode: AgentDataReceivingMode { get set }
    func reactToActiveConnection()
    func reactToInactiveConnection()
}

extension SdkChatSubOffline {
    private static let offlineMessageAddingDelay = 0.6 // In terms of the product vision the delay should be equal 1 second, but we consider message delivery confirmation delay
    
    enum OfflineActionTiming {
        case skip
        case immediate
        case delay
    }
    
    enum OfflineMessageNature {
        case missing
        case outgoing
        case incoming
        case offline
        case existing
    }
}

class SdkChatSubOffline: ISdkChatSubOffline {
    var customText: String?
    var userDataReceivingMode: AgentDataReceivingMode = .channel

    private var areChannelAgentsOffline = false
    private var areChatAgentsOffline = false
    
    private var offlineMessageTimer: Timer?
    
    private var chatEventObserver: JVBroadcastObserver<SdkChatEvent>?
    private var messagingEventObserver: JVBroadcastObserver<SdkMessagingEvent>?

    private let databaseDriver: JVIDatabaseDriver
    private let preferencesDriver: IPreferencesDriver
    private let chatEventObservable: JVBroadcastTool<SdkChatEvent>
    private let messagingEventObservable: JVBroadcastTool<SdkMessagingEvent>
    private let chatContext: ISdkChatContext
    private let chatSubStorage: ISdkChatSubStorage
    
    private var alreadyHandledUids = [String]()
    private var socketConnectedAt = Date.distantPast
    
    init(
        databaseDriver: JVIDatabaseDriver,
        preferencesDriver: IPreferencesDriver,
        chatEventObservable: JVBroadcastTool<SdkChatEvent>,
        messagingEventObservable: JVBroadcastTool<SdkMessagingEvent>,
        chatContext: ISdkChatContext,
        chatSubStorage: ISdkChatSubStorage
    ) {
        self.databaseDriver = databaseDriver
        self.preferencesDriver = preferencesDriver
        self.chatEventObservable = chatEventObservable
        self.messagingEventObservable = messagingEventObservable

        self.chatContext = chatContext
        self.chatSubStorage = chatSubStorage
        
        chatEventObserver = chatEventObservable.addObserver { [weak self] event in
            self?.handleChatEvent(event)
        }
        
        messagingEventObserver = messagingEventObservable.addObserver { [weak self] event in
            self?.handleMessagingEvent(event)
        }
    }
    
    func reactToActiveConnection() {
        socketConnectedAt = Date()
        
        DispatchQueue.main.async { [unowned self] in
            schedulePerforming(after: 2)
        }
    }
    
    func reactToInactiveConnection() {
        socketConnectedAt = .distantPast
    }
    
    private func handleChatEvent(_ event: SdkChatEvent) {
        switch event {
        case let .channelAgentsUpdated(agents):
            areChannelAgentsOffline = agents.isEmpty
        case let .chatAgentsUpdated(agents):
            let activeAgents = agents.compactMap(\.resolved).filter { $0.state == .active }
            areChatAgentsOffline = activeAgents.isEmpty
        default:
            break
        }
        
        performActualAction()
    }
    
    private func handleMessagingEvent(_ event: SdkMessagingEvent) {
        switch event {
        case .messagesUpserted(let messagesRefs):
            let messages = messagesRefs.compactMap(\.resolved)
            guard !messages.filter(\.jv_isValid).map(\.type).contains("offline") else { break }
            let messagesUids = messages.map(\.UUID)
            guard !Set(alreadyHandledUids).isSuperset(of: messagesUids) else { break }
            alreadyHandledUids = (alreadyHandledUids + messagesUids).suffix(10)
            performActualAction()
        default:
            break
        }
        
//        guard case .messagesUpserted(let messages) = event
//        else {
//            return
//        }
//
//        switch detectActionTiming(for: messages) {
//        case .immediate:
//            performActualAction()
//        case .delay:
//            Timer.scheduledTimer(
//                withTimeInterval: Self.offlineMessageAddingDelay,
//                repeats: false,
//                block: { [unowned self] _ in performActualAction() })
//        case .skip:
//            break
//        }
    }
    
    @objc private func performActualAction() {
        assert(Thread.isMainThread)
        
        let contactFormWasShownAt = preferencesDriver.retrieveAccessor(forToken: .contactInfoWasShownAt).date
        let currentNature = detectCurrentNature(after: contactFormWasShownAt)
        let nextNature = detectNextNature(after: contactFormWasShownAt)

        switch (currentNature, nextNature) {
        case (.offline, .offline):
            break
        case (.existing, .offline):
            removeMessageFromHistory()
            appendMessageToHistory()
        case (_, .offline):
            appendMessageToHistory()
        case (.missing, .missing):
            break
        case (_, .missing):
            removeMessageFromHistory()
        default:
            break
        }
    }
    
    private func detectCurrentNature(after anchorDate: Date?) -> OfflineMessageNature {
        let offlineMessage = chatSubStorage.message(withLocalId: JVSDKMessageOfflineChange.id)
        
        guard let chatId = chatContext.chatRef?.resolved?.ID,
              let lastMessage = chatSubStorage.history(chatId: chatId, after: anchorDate).first
        else {
            return (offlineMessage == nil ? .missing : .existing)
        }
        
        if let offlineMessage = offlineMessage {
            return (lastMessage.UUID == offlineMessage.UUID ? .offline : .existing)
        }

        if lastMessage.direction == .outgoing {
            return .outgoing
        }
        else if lastMessage.type == "offline" {
            return .offline
        }
        else {
            return .incoming
        }
    }
    
    private func detectNextNature(after anchorDate: Date?) -> OfflineMessageNature {
        guard let chatId = chatContext.chatRef?.resolved?.ID,
              let lastMessage = chatSubStorage.history(chatId: chatId, after: anchorDate).first
        else {
            return .missing
        }
        
        if socketConnectedAt == .distantPast {
            return .missing
        }
        else if Date().timeIntervalSince(socketConnectedAt) < 2 {
            return .missing
        }
        
        switch userDataReceivingMode {
        case .channel where jv_not(areChannelAgentsOffline):
            return .missing
        case .channel:
            break
        case .chat where jv_not(areChatAgentsOffline):
            return .missing
        case .chat:
            break
        }
        
        if lastMessage.type == "offline" {
            return .offline
        }
        
        if lastMessage.direction != .outgoing {
            return .missing
        }
        
        if let anchorDate = anchorDate, lastMessage.date < anchorDate {
            return .missing
        }
        else {
            return .offline
        }
    }
    
    private func detectActionTiming(for messages: [JVMessage]) -> OfflineActionTiming {
        func _isDelivered(message: JVMessage) -> Bool {
            return
                message.status != nil &&
                message.status != .sent &&
                !message.m_sending_failed
        }
        
        for message in messages {
            if message.type != "system" && _isDelivered(message: message) {
                switch message.sender?.senderType {
                case .client:
                    return .delay
                case .agent:
                    return .immediate
                default:
                    return .skip
                }
            }
            else if message.localID == JVSDKMessageOfflineChange.id {
                return .skip
            }
        }
        
        return .immediate
    }
    
    private func appendMessageToHistory() {
        guard let offlineText = customText?.jv_valuable,
              let offlineMessage = chatSubStorage.storeMessage(change: JVSDKMessageOfflineChange(message: offlineText))
        else {
            return
        }
        
        offlineMessageTimer?.invalidate()
        offlineMessageTimer = Timer.scheduledTimer(
            withTimeInterval: Self.offlineMessageAddingDelay,
            repeats: false,
            block: { [unowned self] _ in
                let ref = databaseDriver.reference(to: offlineMessage)
                messagingEventObservable.broadcast(.messagesUpserted([ref]), async: .main)
            })
    }
    
    private func removeMessageFromHistory() {
        guard let offlineMessage = chatSubStorage.message(withLocalId: JVSDKMessageOfflineChange.id)
        else {
            return
        }
        
        offlineMessageTimer?.invalidate()
        
        let ref = databaseDriver.reference(to: offlineMessage)
        messagingEventObservable.broadcast(.messagesRemoved([ref]))
        chatSubStorage.removeMessages([offlineMessage])
    }
    
    private func schedulePerforming(after seconds: TimeInterval) {
        Timer.scheduledTimer(
            timeInterval: seconds,
            target: self,
            selector: #selector(performActualAction),
            userInfo: nil,
            repeats: false)
    }
}
