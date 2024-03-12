//
//  SdkChatSubStorage.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 30.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import JMCodingKit

enum SdkChatSubStorageMessageTiming {
    case regular
    case frozen
}

enum SdkChatSubStorageEvent {
    case messageResending(_ message: JVMessage)
    case messageSendingFailure(message: JVMessage)
}

protocol ISdkChatSubStorage: IBaseChattingSubStorage {
    var eventSignal: JVBroadcastTool<SdkChatSubStorageEvent> { get }
    
    func message(withLocalId localId: String) -> JVMessage?
    func history(chatId: Int, after anchorDate: Date?, limit: Int) -> [JVMessage]
    func historyIdsBetween(chatId: Int, firstId: Int, lastId: Int) -> [Int]
    func lastSyncedMessage(chatId: Int) -> JVMessage?
    func storeOutgoingMessage(localID: String, clientID: Int, chatID: Int, type: JVMessageType, content: JVMessageContent, status: JVMessageStatus?, timing: SdkChatSubStorageMessageTiming, orderingIndex: Int) -> JVMessage?
    func retrieveQueuedMessages(chatId: Int) -> [JVMessage]
    func resendMessage(_ message: JVMessage)
    func deleteMessage(_ message: JVMessage)
    func createChat(withChatID chatId: Int) -> JVChat?
    func turnContactForm(message: JVMessage, status: JVMessageBodyContactFormStatus, details: JsonElement?)
    func turnRateForm(message: JVMessage, details: String)
    func agents() -> [JVAgent]
    func markMessagesAsSeen(to messageId: Int, inChatWithId chatId: Int) -> [JVMessage]
    func markSendingStart(message: JVMessage)
    func markSendingFailure(message: JVMessage)
    @discardableResult func upsertAgent(havingId id: Int, with: [SdkChatProtoUserSubject]) -> JVAgent?
    func makeAllAgentsOffline()
    @discardableResult func upsertMessage(havingId id: Int, inChatWithId chatId: Int, with subjects: [SdkChatProtoMessageSubject]) -> JVMessage?
    @discardableResult func upsertMessage(byPrivateId privateId: String, inChatWithId chatId: Int, with subjects: [SdkChatProtoMessageSubject]) -> JVMessage?
    func removeMessages(_ messagesToRemove: [JVMessage])
    func deleteAllMessages()
}

class SdkChatSubStorage: BaseChattingSubStorage, ISdkChatSubStorage {
    // MARK: - Public properties
    
    let eventSignal = JVBroadcastTool<SdkChatSubStorageEvent>()
    
    // MARK: - Private properties
    
    private let sessionContext: ISdkSessionContext
    private let keychainDriver: IKeychainDriver
    
    // MARK: - Init
    
    init(
        sessionContext: ISdkSessionContext,
        clientContext: ISdkClientContext,
        databaseDriver: JVIDatabaseDriver,
        keychainDriver: IKeychainDriver,
        systemMessagingService: ISystemMessagingService
    ) {
        self.sessionContext = sessionContext
        self.keychainDriver = keychainDriver
        
        super.init(
            userContext: clientContext,
            databaseDriver: databaseDriver,
            systemMessagingService: systemMessagingService
        )
    }
    
    // MARK: - Public methods
    
    var userContext: ISdkClientContext {
        return userContextAny as! ISdkClientContext
    }
    
    @discardableResult
    override func storeMessage(change: JVDatabaseModelChange) -> JVMessage? {
        super.storeMessage(change: change)
    }
    
    func message(withLocalId localId: String) -> JVMessage? {
        let key = JVDatabaseModelCustomId(key: "m_local_id", value: localId)
        guard
            let message = databaseDriver.object(JVMessage.self, customId: key),
            let _ = jv_validate(message)
        else {
//            journal {"Message under localId[\(localId)] was invalidated"}
            return nil
        }
        return message
    }
    
    func history(chatId: Int, after anchorDate: Date?, limit: Int) -> [JVMessage] {
        let filter = NSPredicate(
            format: "(m_chat_id == %lld OR m_chat_id == 0) AND m_is_hidden == false AND m_date > %@",
            argumentArray: [
                chatId,
                anchorDate ?? .distantPast
            ]
        )
        
        let messages = databaseDriver.objects(
            JVMessage.self,
            options: JVDatabaseRequestOptions(
                filter: filter,
                limit: limit,
                sortBy: [
                    JVDatabaseResponseSort(keyPath: "m_date", ascending: false),
                    JVDatabaseResponseSort(keyPath: "m_ordering_index", ascending: false),
                    JVDatabaseResponseSort(keyPath: "m_id", ascending: false)
                ]
            )
        )
        
//        let validatedMessages = messages.compactMap { jv_validate($0) }
//        if !(messages.count == validatedMessages.count) {
//            journal {"Some messages from database are invalid"}
//        }
        
        return messages
    }
    
    func historyIdsBetween(chatId: Int, firstId: Int, lastId: Int) -> [Int] {
        let filter = NSPredicate(
            format: "(m_chat_id == %lld OR m_chat_id == 0) AND m_is_hidden == false AND m_id >= %lld AND m_id <= %lld",
            argumentArray: [
                chatId,
                firstId,
                lastId
            ]
        )
        
        let messages = databaseDriver.objects(
            JVMessage.self,
            options: JVDatabaseRequestOptions(
                filter: filter,
                properties: ["m_id"],
                sortBy: [
                    JVDatabaseResponseSort(keyPath: "m_date", ascending: false),
                    JVDatabaseResponseSort(keyPath: "m_ordering_index", ascending: false),
                    JVDatabaseResponseSort(keyPath: "m_id", ascending: false)
                ]
            )
        )
        
        return messages.map(\.ID)
    }
    
    func lastSyncedMessage(chatId: Int) -> JVMessage? {
        let filter = NSPredicate(
            format: "(m_chat_id == %lld OR m_chat_id == 0) AND (m_id > 0) AND (m_is_hidden == false) AND (m_sender != nil)",
            argumentArray: [
                chatId
            ]
        )
        
        let messages = databaseDriver.objects(
            JVMessage.self,
            options: JVDatabaseRequestOptions(
                filter: filter,
                sortBy: [
                    JVDatabaseResponseSort(keyPath: "m_date", ascending: false),
                    JVDatabaseResponseSort(keyPath: "m_ordering_index", ascending: false),
                    JVDatabaseResponseSort(keyPath: "m_id", ascending: false)
                ]
            )
        )
        
        return messages.first
    }
    
    func storeOutgoingMessage(localID: String, clientID: Int, chatID: Int, type: JVMessageType, content: JVMessageContent, status: JVMessageStatus?, timing: SdkChatSubStorageMessageTiming, orderingIndex: Int) -> JVMessage? {
        var updates: [JVMessagePropertyUpdate] = [
            .localId(localID),
            .chatId(chatID),
            .sender(.client(clientID == 0 ? 1 : clientID)),
            .typeInitial(type),
            .isIncoming(false),
            .orderingIndex(orderingIndex)
        ]
        
        if type == .message {
            updates.append(.mustBeSent)
        }
        
        if let status = status {
            updates.append(.status(status))
        }
        
        switch timing {
        case .regular:
            updates.append(.date(Date()))
        case .frozen:
            updates.append(.dateFreeze(Date()))
        }
        
        switch content {
        case let .text(data):
            updates.append(.text(data))
            
        case let .photo(mime, name, link, dataSize, width, height, _, _):
            let messageMediaChange = JVMessageMediaGeneralChange(
                type: JVMessageMediaType.photo.rawValue,
                mime: mime,
                name: name,
                link: link,
                size: dataSize,
                width: width,
                height: height
            )
            updates.append(.media(messageMediaChange))
            
        case let .file(mime, name, link, _):
            let messageMediaChange = JVMessageMediaGeneralChange(
                type: JVMessageMediaType.document.rawValue,
                mime: mime,
                name: name,
                link: link,
                size: 0,
                width: 0,
                height: 0
            )
            updates.append(.media(messageMediaChange))
            
        case let .contactForm(status):
            updates.append(.text(status.rawValue))
        case .rateForm:
            break
        default:
            break
        }
        
        let change: JVDatabaseModelChange
        do {
            change = try JVSdkMessageAtomChange(localId: localID, updates: updates)
        }
        catch let error as JVSdkMessageAtomChangeInitError {
            journal {"Failed creating the Atom change with exception[\(String(describing: error.errorDescription))]"}
            return nil
        }
        catch let error {
            journal {"Failed creating the Atom change with unknown exception[\(String(describing: error.localizedDescription))]"}
            return nil
        }
        
        let message = storeMessage(change: change)
        return message
    }
    
    func retrieveQueuedMessages(chatId: Int) -> [JVMessage] {
        var messages = [JVMessage]()
        
        databaseDriver.read { context in
            messages = context.objects(
                JVMessage.self,
                options: JVDatabaseRequestOptions(
                    filter: NSPredicate(format: "m_chat_id == %lld AND m_status == 'queued'", argumentArray: [chatId]),
                    sortBy: [JVDatabaseResponseSort(keyPath: "m_date", ascending: true)]
                ))
        }
        
        return messages
    }
    
    func resendMessage(_ message: JVMessage) {
        guard let _ = jv_validate(message) else {
            journal {"Message is already invalidated"}
            return
        }
        
        switch message.status {
        case .queued:
            databaseDriver.readwrite { context in
                message.apply(
                    context: context,
                    change: JVSdkMessageStatusChange(
                        id: message.ID,
                        localId: message.localID,
                        status: nil,
                        sendingDate: nil,
                        date: nil
                    ))
            }
            
        case nil:
            break
            
        case _ where message.m_sending_failed:
            databaseDriver.readwrite { [weak self] context in
                message.apply(
                    context: context,
                    change: JVSdkMessageStatusChange(
                        id: message.ID,
                        localId: message.localID,
                        status: nil,
                        sendingDate: nil,
                        date: Date()
                    )
                )
                
                message.apply(
                    context: context,
                    change: JVMessageSendingChange(
                        localID: message.localID,
                        sendingDate: Date().timeIntervalSince1970,
                        sendingFailed: false
                    ))
                
                self?.eventSignal.broadcast(.messageResending(message))
            }
            
        default:
            break
        }
    }
    
    func deleteMessage(_ message: JVMessage) {
        databaseDriver.customRemove(objects: [message], recursive: true)
    }
    
    override func chatWithID(_ chatID: Int) -> JVChat? {
        guard
            let chat = super.chatWithID(chatID),
            let _ = jv_validate(chat)
        else {
            journal {"Chat is invalidated"}
            return nil
        }
        
        return chat
    }
    
    @discardableResult
    func createChat(withChatID chatId: Int) -> JVChat? {
        guard let channelId = sessionContext.accountConfig?.channelId else { return nil }
        let channelHash = CRC32.encrypt(channelId)
        
        var chat: JVChat?
        
        databaseDriver.readwrite { context in
            chat = context.insert(
                of: JVChat.self,
                with: JVChatShortChange(
                    ID: chatId,
                    client: JVClientShortChange(
                        ID: userContext.clientHash,
                        channelID: channelHash,
                        task: nil
                    ),
                    attendee: nil,
                    teammateID: nil,
                    isGroup: false,
                    title: nil,
                    about: nil,
                    icon: nil,
                    isArchived: false
                )
            )
        }
        
        return chat
    }
    
    func turnContactForm(message: JVMessage, status: JVMessageBodyContactFormStatus, details: JsonElement?) {
        do {
            let detailsRaw = JsonCoder().encodeToRaw(details ?? .ordict(.init()))
            
            let change = try JVSdkMessageAtomChange(
                localId: message.localID,
                updates: [
                    .text(status.rawValue),
                    .details(detailsRaw ?? String())
                ]
            )
            
            databaseDriver.readwrite { context in
                message.performApply(
                    context: context,
                    environment: context.environment,
                    change: change)
            }
        }
        catch {
        }
    }
    
    func turnRateForm(message: JVMessage, details: String) {
        do {
            let change = try JVSdkMessageAtomChange(
                localId: message.localID,
                updates: [
                    .details(details)
                ]
            )
            
            databaseDriver.readwrite { context in
                message.performApply(
                    context: context,
                    environment: context.environment,
                    change: change)
            }
        } catch { }
    }
    
    func agents() -> [JVAgent] {
        databaseDriver.agents()
    }
    
    @discardableResult
    func markMessagesAsSeen(to messageId: Int, inChatWithId chatId: Int) -> [JVMessage] {
        let filter = NSPredicate(
            format: "(m_chat_id == %lld OR m_chat_id == 0) AND m_is_hidden == false AND m_status != %@",
            argumentArray: [
                chatId,
                JVMessageStatus.seen.rawValue
            ]
        )
        
        let messages = databaseDriver.objects(
            JVMessage.self,
            options: JVDatabaseRequestOptions(
                filter: filter
            )
        )
        
        databaseDriver.readwrite { context in
            for message in messages {
                message.m_status = JVMessageStatus.seen.rawValue
            }
        }

        return messages
    }
    
    func markSendingStart(message: JVMessage) {
        databaseDriver.readwrite { context in
            message.apply(
                context: context,
                change: JVSdkMessageStatusChange(
                    id: message.ID,
                    localId: message.localID,
                    status: JVMessageStatus.sent,
                    sendingDate: Date(),
                    date: nil
                )
            )
        }
    }
    
    func markSendingFailure(message: JVMessage) {
        guard let _ = jv_validate(message) else {
            journal {"Message is invalidated"}
            return
        }
        
        databaseDriver.readwrite { context in
//            guard !message.isInvalidated else { return }            
            message.apply(
                context: context,
                change: JVMessageSendingChange(
                    localID: message.localID,
                    sendingDate: nil,
                    sendingFailed: true
                )
            )
            
            self.eventSignal.broadcast(.messageSendingFailure(message: message))
        }
    }
    
    @discardableResult
    func upsertAgent(havingId id: Int, with subjects: [SdkChatProtoUserSubject]) -> JVAgent? {
        var updates = agentPropertyUpdates(fromSubjects: subjects)
        if updates.contains(where: { update in
            if case .displayName = update { return true } else { return false }
        }), !(updates.contains(where: { update in
            if case .avatarLink = update { return true } else { return false }
        })) {
            updates.append(.avatarLink(nil))
        }
        
        let change = SDKAgentAtomChange(id: id, updates: updates)
        let upsertedAgent = storeAgents(changes: [change], exclusive: false).first
        
        return upsertedAgent
    }
    
    func makeAllAgentsOffline() {
        databaseDriver.readwrite { context in
            let agents = context.objects(JVAgent.self, options: nil)
            for agent in agents {
                agent.apply(
                    context: context,
                    change: JVAgentStateChange(
                        ID: agent.ID,
                        state: JVAgentState.none.rawValue
                    ))
            }
        }
    }
    
    @discardableResult
    func upsertMessage(havingId id: Int, inChatWithId chatId: Int, with subjects: [SdkChatProtoMessageSubject]) -> JVMessage? {
        let updates = messagePropertyUpdates(fromSubjects: subjects, forMessageInChatWithId: chatId)
        guard let change = try? JVSdkMessageAtomChange(id: id, updates: updates) else { return nil }
        
        let upsertedMessage = storeMessage(change: change)
        return upsertedMessage
    }
    
    @discardableResult
    func upsertMessage(byPrivateId privateId: String, inChatWithId chatId: Int, with subjects: [SdkChatProtoMessageSubject]) -> JVMessage? {
        let updates = messagePropertyUpdates(fromSubjects: subjects, forMessageInChatWithId: chatId)
        guard let change = try? JVSdkMessageAtomChange(localId: privateId, updates: updates) else { return nil }

        let upsertedMessage = storeMessage(change: change)
        return upsertedMessage
    }
    
    func removeMessages(_ messagesToRemove: [JVMessage]) {
        databaseDriver.readwrite { context in
            context.removeMessages(uuids: messagesToRemove.map(\.UUID))
        }
    }
    
    func deleteAllMessages() {
        databaseDriver.readwrite { context in
            let messages = databaseDriver.objects(JVMessage.self, options: nil)
            _ = context.simpleRemove(objects: messages)
        }
    }
    
    // MARK: - Private methods
    
    private func messagePropertyUpdates(fromSubjects subjects: [SdkChatProtoMessageSubject], forMessageInChatWithId chatId: Int) -> [JVMessagePropertyUpdate] {
        var updates: [JVMessagePropertyUpdate] = [
            .chatId(chatId),
            .isSendingFailed(false)
        ]
        
        updates = subjects.reduce(updates) { updates, subject in
            var accumulatingUpdates: [JVMessagePropertyUpdate] = updates
            
            switch subject {
            case let .delivered(id, privateId, date): // message 'id' is the first associated value. No need to access it here because the associated value id and the transaction meta id must be equal. If it's not true, there's a bug.
                
                accumulatingUpdates += [
                    .id(id),
                    .date(date),
                    .status(JVMessageStatus.delivered),
                    .localId(privateId)
                ]
                
            case let .received(id, data, media, userId, date):
                if userId == userContext.clientId {
                    accumulatingUpdates += [
                        .sender(.client(userContext.clientHash)),
                        .isIncoming(false)
                    ]
                } else if let agentId = Int(userId) {
                    accumulatingUpdates += [
                        .sender(.agent(agentId)),
                        .isIncoming(true)
                    ]
                }
                
                accumulatingUpdates += [
                    .id(id),
                    .text((data ?? "").jv_trimmed()),
                    .date(date),
                    .typeInitial(.message),
                    { () -> JVMessagePropertyUpdate in
                        guard
                            let lastSeenMessageId = keychainDriver.retrieveAccessor(forToken: .lastSeenMessageId, usingClientToken: true).number,
                            let lastSeedMessage = messageWithID(lastSeenMessageId)
                        else { return .status(.delivered) }
                        
                        if lastSeedMessage.date != date {
                            return date <= lastSeedMessage.date ? .status(.seen) : .status(.delivered)
                        } else {
                            return id <= lastSeenMessageId ? .status(.seen) : .status(.delivered)
                        }
                    }()
                ]
                
                if let media = media {
                    let messageMediaChange = JVMessageMediaGeneralChange(
                        type: media.type.rawValue,
                        mime: media.mime,
                        name: media.name,
                        link: media.link,
                        size: 0,
                        width: 0,
                        height: 0
                    )
                    
                    accumulatingUpdates += [.media(messageMediaChange)]
                }
                
            case .seen: // Associated values are: id, date
                accumulatingUpdates += [.status(JVMessageStatus.seen)]
//
//                if message.text.isEmpty {
//                    accumulatingUpdates += [.isHidden(true)]
//                }
            case .rate:
                break
            }
            
            return accumulatingUpdates
        }
        
        return updates
    }
    
    private func agentPropertyUpdates(fromSubjects subjects: [SdkChatProtoUserSubject]) -> [AgentPropertyUpdate] {
        let updates: [AgentPropertyUpdate] = subjects
            .reduce([]) { updates, subject in
                switch subject {
                case let .statusUpdated(status, _):
                    return updates + [
                        .status(JVAgentState(string: status))
                    ]
                
                case let .nameUpdated(name, _):
                    return updates + [.displayName(name)]
                    
                case let .titleUpdated(title, _):
                    return updates + [.title(title)]
                    
                case let .photoUpdated(photoURLString, _):
                    return updates + [.avatarLink(URL(string: photoURLString))]
                    
                case .switchingDataReceivingMode:
                    return updates
                }
        }
        
        return updates
    }
    
    private func splitIntoParts(messageIdWithTS idWithTS: String) -> (Int?, Date?) {
        let parts = idWithTS.split(separator: ".")
        let id = parts.first.flatMap(String.init).flatMap(Int.init)
        let date = parts.last
            .flatMap(String.init)
            .flatMap(Int.init)
            .flatMap(TimeInterval.init)
            .flatMap(Date.init(timeIntervalSince1970:))
        return (id: id, date: date)
    }
}

extension JVAgent {
    func detach() -> JVAgent {
        let agent = JVAgent(context: managedObjectContext!)
        agent.m_id = m_id
        agent.m_public_id = m_public_id
        agent.m_display_name = m_display_name
        agent.m_avatar_link = m_avatar_link
        agent.m_email = m_email
        agent.m_phone = m_phone
        agent.m_title = m_title
        agent.m_chat = m_chat
        return agent
    }
}

extension JVAgentState {
    init(string: String) {
        switch string {
        case "online": self = .active
        case "offline": self = .away
        default: self = .none
        }
    }
}

/*
extension JVIDatabaseDriver {
    func agents() -> [JVAgent] {
        var agents = [JVAgent]()
        
        read { context in
            agents = context.objects(
                JVAgent.self,
                options: JVDatabaseRequestOptions(
                    filter: nil
                )
            )
        }
        
        return agents
    }
}
 */

extension JVIDatabaseDriver {
    func agents() -> [JVAgent] {
        var agents = [JVAgent]()
        
        read { context in
            agents = context.objects(
                JVAgent.self,
                options: JVDatabaseRequestOptions(
                    filter: nil
                )
            )
        }
        
        return agents
    }
}
