//
//  SdkChatSubHello.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 17.03.2022.
//

import Foundation

protocol ISdkChatSubHello: AnyObject {
    var customText: String? { get set }
    func reactToActiveConnection()
    func reactToInactiveConnection()
}

extension SdkChatSubHello {
    private static let messageAddingDelay = 0.6 // In terms of the product vision the delay should be equal 1 second, but we consider message delivery confirmation delay
    
    enum HelloActionTiming {
        case skip
        case immediate
        case delay
    }
    
    enum HelloMessageNature {
        case missing
        case outgoing
        case incoming
        case offline
        case existing
    }
}

class SdkChatSubHello: ISdkChatSubHello {
    var customText: String?

    private var messageTimer: Timer?
    
    private let databaseDriver: JVIDatabaseDriver
    private let preferencesDriver: IPreferencesDriver
    private let messagingEventObservable: JVBroadcastTool<SdkMessagingEvent>
    private let chatContext: ISdkChatContext
    private let chatSubStorage: ISdkChatSubStorage
    
    private var alreadyHandledUids = [String]()
    private var socketConnectedAt = Date.distantPast
    
    init(
        databaseDriver: JVIDatabaseDriver,
        preferencesDriver: IPreferencesDriver,
        messagingEventObservable: JVBroadcastTool<SdkMessagingEvent>,
        chatContext: ISdkChatContext,
        chatSubStorage: ISdkChatSubStorage
    ) {
        self.databaseDriver = databaseDriver
        self.preferencesDriver = preferencesDriver
        self.messagingEventObservable = messagingEventObservable

        self.chatContext = chatContext
        self.chatSubStorage = chatSubStorage
    }
    
    func reactToActiveConnection() {
        socketConnectedAt = Date()
        
        DispatchQueue.main.async { [unowned self] in
            performActualAction()
            schedulePerforming(after: 2)
        }
    }
    
    func reactToInactiveConnection() {
        socketConnectedAt = .distantPast
    }
    
    @objc private func performActualAction() {
        assert(Thread.isMainThread)
        
        guard let chatId = chatContext.chatRef?.resolved?.ID
        else {
            return
        }
        
        let messages = chatSubStorage.history(chatId: chatId, after: nil)
        if messages.isEmpty, Date().timeIntervalSince(socketConnectedAt) > 2 {
            messageTimer?.invalidate()
            messageTimer = Timer.scheduledTimer(
                withTimeInterval: Self.messageAddingDelay,
                repeats: false,
                block: { [unowned self] _ in
                    placeMessageToHistory()
                })
        }
        else if let recentMessage = messages.first, recentMessage.localID == JVSDKMessageHelloChange.id {
            placeMessageToHistory()
        }
    }
    
    private func placeMessageToHistory() {
        guard let chatId = chatContext.chatRef?.resolved?.ID,
              let text = customText?.jv_valuable
        else {
            return
        }
        
        let change = JVSDKMessageHelloChange(chatId: chatId, message: text)
        let message = chatSubStorage.storeMessage(change: change)
        
        let ref = databaseDriver.reference(to: message)
        messagingEventObservable.broadcast(.messagesUpserted([ref]), async: .main)
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
