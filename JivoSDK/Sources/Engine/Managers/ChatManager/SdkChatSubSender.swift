//
//  ChatSubSender.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 01.10.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation


enum SdkChatSubSenderEvent {
}

protocol ISdkChatSubSender {
    var eventSignal: JVBroadcastTool<SdkChatSubStorageEvent> { get }
    func run()
    func stop()
}

final class SdkChatSubSender: ISdkChatSubSender {
    let eventSignal = JVBroadcastTool<SdkChatSubStorageEvent>()
    
    private let clientContext: ISdkClientContext
    private let messagingContext: ISdkMessagingContext
    private let databaseDriver: JVIDatabaseDriver
    private let proto: ISdkChatProto
    private let subStorage: ISdkChatSubStorage
    private let systemMessagingService: ISystemMessagingService
    private let scheduledActionTool: ISchedulingDriver
//    private let messageAddObservable = JVBroadcastTool<(message: JVMessage, animated: Bool)>()
//    private let messageUpdateObservable = JVBroadcastTool<JVMessage>()

    private var firstRun = true
    private var outgoingMessagesListener: JVDatabaseListener?

    init(clientContext: ISdkClientContext,
         messagingContext: ISdkMessagingContext,
         databaseDriver: JVIDatabaseDriver,
         proto: ISdkChatProto,
         subStorage: ISdkChatSubStorage,
         systemMessagingService: ISystemMessagingService,
         scheduledActionTool: ISchedulingDriver) {
        self.clientContext = clientContext
        self.messagingContext = messagingContext
        self.databaseDriver = databaseDriver
        self.proto = proto
        self.subStorage = subStorage
        self.systemMessagingService = systemMessagingService
        self.scheduledActionTool = scheduledActionTool
    }
    
    func run() {
        outgoingMessagesListener = databaseDriver.subscribe(
            JVMessage.self,
            options: JVDatabaseRequestOptions(
                filter: NSPredicate(format: "m_status = '' AND m_type != 'system' AND m_type != 'offline' AND m_type != 'proactive' AND m_type != 'contact_form'"),
                sortBy: [JVDatabaseResponseSort(keyPath: "m_date", ascending: true)]
            ),
            callback: { [unowned self] messages in
                self.handleMessagesToSend(messages)
            }
        )
        
        if firstRun {
            firstRun = false
            markSentMessagesAsFailed()
        }
    }
    
    func stop() {
        outgoingMessagesListener = nil
    }
    
    private func markSentMessagesAsFailed() {
        let messages = databaseDriver.objects(
            JVMessage.self,
            options: JVDatabaseRequestOptions(
                filter: NSPredicate(format: "m_status = 'sent'"),
                sortBy: [JVDatabaseResponseSort(keyPath: "m_date", ascending: true)]
            )
        )
        messages.forEach {
            self.subStorage.markSendingFailure(message: $0)
        }
    }
    
    private func handleMessagesToSend(_ outmessages: [JVMessage]) {
        for outmessage in outmessages {
            guard let _ = databaseDriver.object(JVChat.self, primaryId: outmessage.chatID)
            else {
                let chatID = outmessage.chatID
                journal {"Missing chat[\(chatID)] for outgoing message"}
                continue
            }
            
            switch outmessage.content {
            case .photo(let mime, _, _, _, _, _):
                proto
                    .sendMessage(outmessage, mime: mime)
            default:
                proto
                    .sendMessage(outmessage, mime: "text/plain")
            }
            
            subStorage.markSendingStart(message: outmessage)
            
            scheduledActionTool.schedule(
                for: .sendingMessage(ID: outmessage.localID),
                delay: 5,
                repeats: false,
                block: { [unowned self] in
                    guard jv_validate(outmessage)?.status == JVMessageStatus.sent
                    else {
                        return
                    }
                    
                    let outmessageRef = subStorage.reference(to: outmessage)
                    subStorage.markSendingFailure(message: outmessage)
                    messagingContext.broadcast(event: .messagesUpserted([outmessageRef]), onQueue: .main)
                }
            )
            
            break
        }
    }
}
