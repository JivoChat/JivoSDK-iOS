//
//  JVMessage+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

public extension JVMessage {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_sender = m_sender_client ?? m_sender_agent ?? m_sender_bot
        }
        
        func _adjustSender(type: String, ID: Int, body: JVMessageBodyGeneralChange?) {
            if let body = body, let _ = body.callID {
                m_sender_agent = body.agentID.flatMap { context.agent(for: $0, provideDefault: true) }
                return
            }
            
            switch type {
            case "client":
                m_sender_client = context.client(for: ID, needsDefault: false)
            case "agent":
                m_sender_agent = context.agent(for: ID, provideDefault: true)
            case "system" where type == "proactive":
                m_sender_agent = context.agent(for: ID, provideDefault: true)
            case "system":
                m_sender_agent = m_body?.call?.agent.flatMap { context.agent(for: $0.ID, provideDefault: true) }
            case "bot":
                m_sender_bot_flag = true
                m_sender_bot = context.bot(for: ID, provideDefault: true)
            case _ where m_client_id > 0:
                m_sender_client = context.client(for: Int(m_client_id), needsDefault: false)
            default:
                assertionFailure()
            }
        }
        
        func _adjustBotMeta(text: String) {
            guard text.contains("⦀")
            else {
                return
            }
            
            let slices = (String(" ") + text).split(separator: "⦀")
            m_text = slices.first.flatMap(String.init)?.jv_trimmed() ?? String()
            
            if m_body == nil {
                m_body = context.insert(of: JVMessageBody.self, with: JVMessageBodyGeneralChange(json: JsonElement()))
            }
            
            m_body?.m_buttons = slices.dropFirst()
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .joined(separator: "\n")
        }
        
        func _adjustIncomingState(clientID: Int?) {
            if let _ = clientID ?? context.clientID(for: Int(m_chat_id)) {
                let value = (m_sender_client.jv_hasValue || m_sender_agent?.isMe == false)
                m_is_incoming = value
            }
            else {
                let value = (m_sender_agent?.isMe == false)
                m_is_incoming = value
            }
        }
        
        func _adjustStatus(status: String?) {
            guard m_status != JVMessageStatus.seen.rawValue else {
                return
            }
            
            if let status = status {
                m_status = (JVMessageStatus(rawValue: status) ?? .delivered).rawValue
            }
            else {
                m_status = JVMessageStatus.delivered.rawValue
            }
        }
        
        func _adjustHidden() {
            if m_type == "comment", m_was_deleted {
                m_is_hidden = true
            }
            else {
                m_is_hidden = false
            }
        }

        func _adjustTask(task: JVMessageBodyTask?) {
            guard let task = task else { return }
            guard let agentID = task.agent?.ID else { return }
            
            let status: String
            switch task.status {
            case .created, .updated:
                status = JVTaskStatus.active.rawValue
            case .completed, .deleted:
                status = JVTaskStatus.unknown.rawValue
            case .fired:
                status = JVTaskStatus.fired.rawValue
            case .unknown:
                status = JVTaskStatus.unknown.rawValue
            }

            _ = context.upsert(
                of: JVTask.self,
                with: JVTaskGeneralChange(
                    ID: task.taskID,
                    agentID: agentID,
                    agent: nil,
                    text: task.text,
                    createdTs: task.createdAt?.timeIntervalSince1970,
                    modifiedTs: task.updatedAt?.timeIntervalSince1970,
                    notifyTs: task.notifyAt.timeIntervalSince1970,
                    status: status
                )
            )
        }
        
        if let c = change as? JVMessageGeneralChange {
            if m_id == 0 { m_id = c.ID.jv_toInt64 }
            m_date = m_date_freezed ? m_date : Date(timeIntervalSince1970: TimeInterval(c.creationTS))
            m_client_id = c.clientID.jv_toInt64
            m_client = context.client(for: Int(m_client_id), needsDefault: false)
            m_chat_id = c.chatID.jv_toInt64
            m_type = c.type
            m_is_markdown = c.isMarkdown
            m_text = c.text.jv_trimmed()
            m_body = context.insert(of: JVMessageBody.self, with: c.body, validOnly: true)
            m_media = context.insert(of: JVMessageMedia.self, with: c.media, validOnly: true)
            
            let updatedReactions = try? PropertyListEncoder().encode(c.reactions)
            if updatedReactions != m_reactions {
                m_reactions = updatedReactions
                context.environment.performMessageRecalculate(uid: UUID)
            }
            
            m_is_offline = c.isOffline
            m_updated_agent = c.updatedBy.flatMap { context.agent(for: $0, provideDefault: false) }
            m_updated_timepoint = c.updatedTs ?? 0
            m_was_deleted = c.isDeleted

            _adjustSender(type: c.senderType, ID: c.senderID, body: c.body)
            _adjustBotMeta(text: c.text)
            _adjustIncomingState(clientID: c.clientID)
            _adjustStatus(status: c.status)
            _adjustHidden()
        }
        else if let c = change as? JVMessageShortChange {
            if m_id == 0 { m_id = c.ID.jv_toInt64 }
            
            m_client_id = c.clientID?.jv_toInt64 ?? 0
            m_client = context.client(for: Int(m_client_id), needsDefault: false)
            m_chat_id = c.chatID.jv_toInt64
            m_type = "message"
            m_is_markdown = false
            m_text = c.text.jv_trimmed()
            m_media = context.insert(of: JVMessageMedia.self, with: c.media, validOnly: true)

            if let date = c.time.jv_parseDateUsingFullFormat() {
                m_date = m_date_freezed ? m_date : date
            }
            else {
                m_date = m_date_freezed ? m_date : Date()
            }
            
            if let senderType = c.senderType.jv_valuable {
                _adjustSender(type: senderType, ID: c.senderID, body: nil)
                _adjustBotMeta(text: c.text)
                _adjustIncomingState(clientID: nil)
                _adjustStatus(status: JVMessageStatus.delivered.rawValue)
                _adjustHidden()
            }
            else if let clientID = c.clientID {
                _adjustSender(type: "client", ID: clientID, body: nil)
                _adjustBotMeta(text: c.text)
                _adjustIncomingState(clientID: clientID)
                _adjustStatus(status: JVMessageStatus.delivered.rawValue)
                _adjustHidden()
            }
            else {
                assertionFailure()
            }
        }
        else if let c = change as? JVMessageLocalChange {
            m_id = c.ID.jv_toInt64
            m_client_id = c.clientID?.jv_toInt64 ?? 0
            m_client = context.client(for: Int(m_client_id), needsDefault: false)
            m_date = m_date_freezed ? m_date : Date(timeIntervalSince1970: TimeInterval(c.creationTS))
            m_chat_id = c.chatID.jv_toInt64
            m_text = c.text.jv_trimmed()
            m_type = c.type
            m_is_markdown = c.isMarkdown
            m_body = context.insert(of: JVMessageBody.self, with: c.body, validOnly: true)
            m_media = context.insert(of: JVMessageMedia.self, with: c.media, validOnly: true)
            m_is_offline = c.isOffline
            m_updated_agent = c.updatedBy.flatMap { context.agent(for: $0, provideDefault: false) }
            m_updated_timepoint = c.updatedTs ?? 0
            m_was_deleted = c.isDeleted

            _adjustSender(type: c.senderType, ID: c.senderID, body: c.body)
            _adjustBotMeta(text: c.text)
            _adjustIncomingState(clientID: nil)
            _adjustStatus(status: JVMessageStatus.delivered.rawValue)
            _adjustHidden()
        }
        else if let c = change as? JVMessageFromClientChange {
            m_id = c.ID.jv_toInt64
            m_date = m_date_freezed ? m_date : Date()
            m_client_id = c.clientID.jv_toInt64
            m_client = context.client(for: Int(m_client_id), needsDefault: false)
            m_chat_id = c.chatID.jv_toInt64
            m_type = "message"
            m_is_markdown = false
            m_text = c.text.jv_trimmed()
            m_sender_client = context.object(JVClient.self, primaryId: c.clientID)
            m_media = context.insert(of: JVMessageMedia.self, with: c.media, validOnly: true)

            _adjustBotMeta(text: c.text)
            _adjustIncomingState(clientID: nil)
            _adjustStatus(status: JVMessageStatus.delivered.rawValue)
            _adjustHidden()
        }
        else if let c = change as? JVMessageFromAgentChange {
            m_id = c.ID.jv_toInt64
            m_client_id = context.clientID(for: c.chatID)?.jv_toInt64 ?? 0
            m_client = context.client(for: Int(m_client_id), needsDefault: false)
            m_date = m_date_freezed ? m_date : c.date
            m_chat_id = c.chatID.jv_toInt64
            m_type = c.type
            m_is_markdown = c.isMarkdown
            m_text = c.text.jv_trimmed()
            m_body = context.insert(of: JVMessageBody.self, with: c.body, validOnly: true)
            m_media = context.insert(of: JVMessageMedia.self, with: c.media, validOnly: true)
            m_updated_agent = c.updatedBy.flatMap { context.agent(for: $0, provideDefault: false) }
            m_updated_timepoint = c.updatedTs ?? 0
            m_was_deleted = c.isDeleted

            _adjustSender(type: c.senderType, ID: c.senderID, body: c.body)
            _adjustBotMeta(text: c.text)
            _adjustIncomingState(clientID: nil)
            _adjustTask(task: m_body?.task)
            _adjustStatus(status: JVMessageStatus.delivered.rawValue)
            _adjustHidden()
        }
        else if let c = change as? JVMessageStateChange {
            m_id = c.globalID.jv_toInt64
            m_date = m_date_freezed ? m_date : (c.date ?? m_date)
            m_sending_date = 0
            m_sending_failed = false
            _adjustStatus(status: c.status ?? m_status)
        }
        else if let c = change as? JVMessageGeneralSystemChange {
            m_client_id = c.clientID?.jv_toInt64 ?? 0
            m_client = context.client(for: Int(m_client_id), needsDefault: false)
            m_chat_id = c.chatID.jv_toInt64
            m_date = m_date_freezed ? m_date : Date(timeIntervalSince1970: c.creationTS)
            m_ordering_index = 1
            m_text = c.text.jv_trimmed()
            m_type = "system"
            m_is_markdown = false
            m_interactive_id = c.interactiveID
            m_icon_link = c.iconLink
            
            _adjustHidden()
        }
        else if let c = change as? JVMessageOutgoingChange {
            m_local_id = c.localID
            m_date = m_date_freezed ? m_date : c.date
            m_client_id = c.clientID?.jv_toInt64 ?? 0
            m_client = context.client(for: Int(m_client_id), needsDefault: false)
            m_chat_id = c.chatID.jv_toInt64
            m_is_incoming = false
            m_type = c.type
            m_is_markdown = false
            m_status = String()
            
            switch c.contents {
            case .text(let text):
                m_text = text.jv_trimmed()
                
            case .comment(let text):
                m_text = text.jv_trimmed()
                
            case .email:
                abort()
                
            case .photo(let mime, let name, let link, let dataSize, let width, let height):
                m_text = "🖼 " + name.jv_trimmed()
                
                m_media = context.insert(
                    of: JVMessageMedia.self,
                    with: JVMessageMediaGeneralChange(
                        type: "photo",
                        mime: mime,
                        name: name,
                        link: link,
                        size: dataSize,
                        width: width,
                        height: height
                    )
                )
                
            case .file(let mime, let name, let link, let size):
                m_text = "📄 " + name.jv_trimmed()
                
                m_media = context.insert(
                    of: JVMessageMedia.self,
                    with: JVMessageMediaGeneralChange(
                        type: "document",
                        mime: mime,
                        name: name,
                        link: link,
                        size: size,
                        width: 0,
                        height: 0
                    )
                )
                
            case .proactive, .offline, .transfer, .transferDepartment, .join, .left, .call, .line, .task, .bot, .order, .conference, .story:
                assertionFailure()
                
            case .contactForm(let status):
                m_text = status.rawValue
            }
            
            _adjustSender(type: c.senderType, ID: c.senderID, body: nil)
            _adjustHidden()
        }
        else if let c = change as? JVMessageSendingChange {
            m_sending_date = c.sendingDate ?? m_sending_date
            m_sending_failed = c.sendingFailed ?? m_sending_failed
        }
        else if let c = change as? JVMessageReadChange {
            m_has_read = c.hasRead
        }
        else if let c = change as? JVMessageTextChange {
            if text != c.text.jv_trimmed() {
                m_text = c.text.jv_trimmed()
            }
        }
        else if let c = change as? JVMessageReactionChange {
            var payload = reactions
            
            let reactionIndex = payload.firstIndex(
                where: { $0.emoji == c.emoji }
            )
            
            let reactorIndex = reactionIndex.flatMap { index in
                payload[index].reactors.firstIndex(
                    where: { $0.subjectKind == c.fromKind && $0.subjectID == c.fromID }
                )
            }
            
            if c.deleted {
                if let reactionIndex = reactionIndex {
                    var reactors = payload[reactionIndex].reactors
                    
                    if let reactorIndex = reactorIndex {
                        reactors.remove(at: reactorIndex)
                    }
                    
                    if reactors.isEmpty {
                        payload.remove(at: reactionIndex)
                    }
                    else {
                        payload[reactionIndex].reactors = reactors
                    }
                }
            }
            else {
                let reactor = JVMessageReactor(subjectKind: c.fromKind, subjectID: c.fromID)
                
                if let reactionIndex = reactionIndex {
                    var reactors = payload[reactionIndex].reactors
                    
                    if reactorIndex == nil {
                        reactors.append(reactor)
                    }
                    
                    payload[reactionIndex].reactors = reactors
                }
                else {
                    let reaction = JVMessageReaction(emoji: c.emoji, reactors: [reactor])
                    payload.append(reaction)
                }
            }
            
            m_reactions = try? PropertyListEncoder().encode(payload)
            
            context.environment.performMessageRecalculate(uid: UUID)
        }
        else if let c = change as? JVMessageSdkAgentChange {
            m_id = c.ID.jv_toInt64
            m_client_id = context.clientID(for: c.chat.ID)?.jv_toInt64 ?? 0
            m_client = context.client(for: Int(m_client_id), needsDefault: false)
            m_date = m_date_freezed ? m_date : c.creationDate
            m_chat_id = c.chat.ID.jv_toInt64
            m_type = c.type
            m_is_markdown = c.isMarkdown
            m_text = c.text.jv_trimmed()
            m_body = context.insert(of: JVMessageBody.self, with: c.body, validOnly: true)
            m_media = context.insert(of: JVMessageMedia.self, with: c.media, validOnly: true)
            m_updated_agent = c.updatedBy.flatMap { context.agent(for: $0, provideDefault: false) }
            m_updated_timepoint = c.updateDate?.timeIntervalSince1970 ?? 0
            m_was_deleted = c.isDeleted

            _adjustSender(type: c.senderType, ID: c.agent.ID, body: c.body)
            _adjustIncomingState(clientID: nil)
            _adjustTask(task: m_body?.task)
            _adjustStatus(status: JVMessageStatus.delivered.rawValue)
            _adjustHidden()
        }
        else if let c = change as? JVMessageSdkClientChange {
            m_id = c.ID.jv_toInt64
            m_local_id = c.localId
            m_date = m_date_freezed ? m_date : c.date
            m_client_id = c.clientId.jv_toInt64
            m_client = context.client(for: Int(m_client_id), needsDefault: false)
            m_chat_id = c.chatId.jv_toInt64
            m_type = c.type
            m_is_markdown = c.isMarkdown
            m_text = c.text
            m_sender_client = context.object(JVClient.self, primaryId: clientID)
            m_media = context.insert(of: JVMessageMedia.self, with: c.media, validOnly: true)
            
            _adjustIncomingState(clientID: nil)
            _adjustStatus(status: JVMessageStatus.delivered.rawValue)
            _adjustHidden()
        }
        else if let c = change as? JVSdkMessageStatusChange {
            m_id = c.id.jv_toInt64
            m_status = c.status?.rawValue ?? String()
            
            if let date = c.date {
                m_date = m_date_freezed ? m_date : date
            }
        }
        else if let c = change as? JVSdkMessageAtomChange {
            c.updates.forEach { update in
                switch update {
                case let .id(newValue):
                    if m_id == 0 && m_id != newValue {
                        m_id = newValue.jv_toInt64
                    }
                    
                    m_is_markdown = true
                    
                case let .localId(newValue):
                    if m_local_id != newValue {
                        m_local_id = newValue
                    }
                    
                case let .text(newValue):
                    if m_text != newValue {
                        m_text = newValue
                    }
                    
                    _adjustBotMeta(text: newValue)

                case let .details(newValue):
                    if m_details != newValue {
                        m_details = newValue
                    }
                    
                case let .date(newValue):
                    if m_date != newValue {
                        m_date = m_date_freezed ? m_date : newValue
                    }
                    
                case let .dateFreeze(newValue):
                    m_date_freezed = true
                    if m_date != newValue {
                        m_date = newValue
                    }
                    
                case let .status(newValue):
                    if m_status != newValue.rawValue {
                        m_status = newValue.rawValue
                    }
                    
                case let .chatId(newValue):
                    if m_chat_id != newValue {
                        m_chat_id = newValue.jv_toInt64
                    }
                    
                case let .media(newValue):
                    let media = context.insert(of: JVMessageMedia.self, with: newValue, validOnly: true)
                    if m_media?.objectID != media?.objectID {
                        m_media = media
                    }
                    
                case let .sender(senderType):
                    switch senderType {
                    case let .client(id):
                        let client = context.client(for: id, needsDefault: true)
                        if m_sender_client?.objectID != client?.objectID {
                            m_sender_client = client
                        }
                        
                    case let .agent(id, displayNameUpdate):
                        let existingAgent = context.agent(for: id, provideDefault: false)
                        let agent = existingAgent ?? { () -> JVAgent? in
                            let defaultAgent = context.agent(for: id, provideDefault: true)
                            if case let JVMessagePropertyUpdate.Sender.DisplayNameUpdatingLogic.updating(with: newValue) = displayNameUpdate {
                                newValue.flatMap { defaultAgent?.m_display_name = $0 }
                            }
                            return defaultAgent
                        }()
                        
                        m_sender_bot_flag = (id < 0)
                        
                        if m_sender_agent?.objectID != agent?.objectID {
                            m_sender_agent = agent
                        }
                    }
                    
                case let .type(newValue):
                    if m_type != newValue.rawValue {
                        m_type = newValue.rawValue
                    }
                
                case let .typeInitial(newValue):
                    if m_type?.jv_valuable == nil {
                        m_type = newValue.rawValue
                    }
                    
                case let .isHidden(newValue):
                    if m_is_hidden != newValue {
                        m_is_hidden = newValue
                    }
                    
                case let .isIncoming(newValue):
                    if m_is_incoming != newValue {
                        m_is_incoming = newValue
                    }
                    
                case let .isSendingFailed(newValue):
                    if m_sending_failed != newValue {
                        m_sending_failed = newValue
                    }
                }
            }
        }
        else if let c = change as? JVSDKMessageOfflineChange {
            m_local_id = c.localId
            m_date = m_date_freezed ? m_date : c.date
            m_type = c.type
            
            if case let .offline(text) = c.content {
                m_text = text
            }
        }
    }
}

open class JVMessageBaseGeneralChange: JVDatabaseModelChange, Comparable {
    public let ID: Int
    public let creationTS: TimeInterval
    public let body: JVMessageBodyGeneralChange?
    public let isOffline: Bool
    
    open override var integerKey: JVDatabaseModelCustomId<Int>? {
        return JVDatabaseModelCustomId(key: "m_id", value: ID)
    }
    
    public init(ID: Int, creationTS: TimeInterval, body: JVMessageBodyGeneralChange?) {
        self.ID = ID
        self.creationTS = creationTS
        self.body = body
        self.isOffline = false
        super.init()
    }
    
    required public init(json: JsonElement) {
        ID = json["msg_id"].intValue
        creationTS = json["created_ts"].doubleValue
        body = json["body"].parse()
        isOffline = (json["source"]["channel_type"].string == "offline")
        super.init(json: json)
    }
    
    public func copy(ID: Int) -> JVMessageBaseGeneralChange {
        abort()
    }
}

open class JVMessageExtendedGeneralChange: JVMessageBaseGeneralChange {
    public let type: String
    public let isMarkdown: Bool
    public let senderType: String
    
    public init(
         ID: Int,
         creationTS: TimeInterval,
         body: JVMessageBodyGeneralChange?,
         type: String,
         isMarkdown: Bool,
         senderType: String
    ) {
        self.type = type
        self.isMarkdown = isMarkdown
        self.senderType = senderType
        
        super.init(
            ID: ID,
            creationTS: creationTS,
            body: body
        )
    }

    required public init(json: JsonElement) {
        type = json["type"].stringValue
        isMarkdown = json["is_markdown"].boolValue
        senderType = json["from"].stringValue
        super.init(json: json)
    }
    
    open override var isValid: Bool {
        if type == "call", !(body?.isValidCall == true) {
            return false
        }
        
        return validateMessage(senderType: senderType, type: type)
    }
}

public final class JVMessageGeneralChange: JVMessageExtendedGeneralChange {
    public let clientID: Int
    public let chatID: Int
    public let senderID: Int
    public let text: String
    public let status: String
    public let media: JVMessageMediaGeneralChange?
    public let updatedBy: Int?
    public let updatedTs: TimeInterval?
    public let reactions: [JVMessageReaction]
    public let isDeleted: Bool
    
    public override var primaryValue: Int {
        abort()
    }
    
    public init(ID: Int,
         clientID: Int,
         chatID: Int,
         type: String,
         isMarkdown: Bool,
         senderID: Int,
         senderType: String,
         text: String,
         creationTS: TimeInterval,
         status: String,
         body: JVMessageBodyGeneralChange?,
         media: JVMessageMediaGeneralChange?,
         updatedBy: Int?,
         updatedTs: TimeInterval?,
         reactions: [JVMessageReaction],
         isDeleted: Bool) {
        self.clientID = clientID
        self.chatID = chatID
        self.senderID = senderID
        self.text = text
        self.status = status
        self.media = media
        self.updatedBy = updatedBy
        self.updatedTs = updatedTs
        self.reactions = reactions
        self.isDeleted = isDeleted
        
        super.init(
            ID: ID,
            creationTS: creationTS,
            body: body,
            type: type,
            isMarkdown: isMarkdown,
            senderType: senderType
        )
    }
    
    required public init(json: JsonElement) {
        clientID = json["client_id"].intValue
        chatID = json["chat_id"].intValue
        senderID = json["from_id"].intValue
        text = json["text"].stringValue
        status = extractStatus(primary: json["statuses"].arrayValue, secondary: json["status"])
        media = json["media"].parse()
        updatedBy = json["updated_by"].int
        updatedTs = json["updated_ts"].double
        reactions = parseReactions(json["reactions"])
        isDeleted = json["deleted"].boolValue
        super.init(json: json)
    }
    
    public override var isValid: Bool {
        if type == "message", media?.type == "conference", senderType == "agent" {
            return false
        }
        
        return super.isValid
    }
    
    public var callID: String? {
        return body?.callID
    }
    
    public override func copy(ID: Int) -> JVMessageBaseGeneralChange {
        return JVMessageGeneralChange(
            ID: ID,
            clientID: clientID,
            chatID: chatID,
            type: type,
            isMarkdown: isMarkdown,
            senderID: senderID,
            senderType: senderType,
            text: text,
            creationTS: creationTS,
            status: status,
            body: body,
            media: media,
            updatedBy: updatedBy,
            updatedTs: updatedTs,
            reactions: reactions,
            isDeleted: isDeleted)
    }
    
    public func copy(clientID: Int) -> JVMessageGeneralChange {
        return JVMessageGeneralChange(
            ID: ID,
            clientID: clientID,
            chatID: chatID,
            type: type,
            isMarkdown: isMarkdown,
            senderID: senderID,
            senderType: senderType,
            text: text,
            creationTS: creationTS,
            status: status,
            body: body,
            media: media,
            updatedBy: updatedBy,
            updatedTs: updatedTs,
            reactions: reactions,
            isDeleted: isDeleted)
    }
}

public final class JVMessageShortChange: JVDatabaseModelChange {
    public let ID: Int
    public let clientID: Int?
    public let chatID: Int
    public let senderType: String
    public let senderID: Int
    public let text: String
    public let isMarkdown: Bool
    public let time: String
    public let media: JVMessageMediaGeneralChange?

    public override var primaryValue: Int {
        abort()
    }
    
    public override var integerKey: JVDatabaseModelCustomId<Int>? {
        return JVDatabaseModelCustomId(key: "m_id", value: ID)
    }
    
    public override var isValid: Bool {
        guard ID > 0 else { return false }
        return true
    }
    
    public init(ID: Int,
         clientID: Int?,
         chatID: Int,
         senderType: String,
         senderID: Int,
         text: String,
         isMarkdown: Bool,
         time: String,
         media: JVMessageMediaGeneralChange?) {
        self.ID = ID
        self.clientID = clientID
        self.chatID = chatID
        self.senderType = senderType
        self.senderID = senderID
        self.text = text
        self.isMarkdown = isMarkdown
        self.time = time
        self.media = media
        super.init()
    }

    required public init(json: JsonElement) {
        ID = json["msg_id"].intValue
        clientID = json["client_id"].int
        chatID = json["chat_id"].intValue
        senderType = json["from"].stringValue
        senderID = json["from_id"].intValue
        text = json["message"].string ?? json["text"].stringValue
        isMarkdown = json["is_markdown"].boolValue
        time = json["time"].stringValue
        media = json["media"].parse()
        super.init(json: json)
    }
    
    public func copy(clientID: Int?) -> JVMessageShortChange {
        return JVMessageShortChange(
            ID: ID,
            clientID: clientID,
            chatID: chatID,
            senderType: senderType,
            senderID: senderID,
            text: text,
            isMarkdown: isMarkdown,
            time: time,
            media: media)
    }
}

public final class JVMessageLocalChange: JVMessageExtendedGeneralChange {
    public let clientID: Int?
    public let chatID: Int
    public let senderID: Int
    public let text: String
    public let media: JVMessageMediaGeneralChange?
    public let updatedBy: Int?
    public let updatedTs: TimeInterval?
    public let isDeleted: Bool

    public override var primaryValue: Int {
        abort()
    }
    
    public init(ID: Int,
         clientID: Int?,
         chatID: Int,
         type: String,
         isMarkdown: Bool,
         senderID: Int,
         senderType: String,
         text: String,
         creationTS: TimeInterval,
         body: JVMessageBodyGeneralChange?,
         media: JVMessageMediaGeneralChange?,
         isOffline: Bool,
         updatedBy: Int?,
         updatedTs: TimeInterval?,
         isDeleted: Bool) {
        self.clientID = clientID
        self.chatID = chatID
        self.senderID = senderID
        self.text = text
        self.media = media
        self.updatedBy = updatedBy
        self.updatedTs = updatedTs
        self.isDeleted = isDeleted
        
        super.init(
            ID: ID,
            creationTS: creationTS,
            body: body,
            type: type,
            isMarkdown: isMarkdown,
            senderType: senderType
        )
    }
    
    required public init(json: JsonElement) {
        clientID = nil
        chatID = json["chat_id"].intValue
        senderID = json["from_id"].intValue
        text = json["text"].stringValue
        media = json["media"].parse()
        updatedBy = json["updated_by"].int
        updatedTs = json["updated_ts"].double
        isDeleted = json["deleted"].boolValue
        super.init(json: json)
    }
    
    public override func copy(ID: Int) -> JVMessageLocalChange {
        return JVMessageLocalChange(
            ID: ID,
            clientID: clientID,
            chatID: chatID,
            type: type,
            isMarkdown: isMarkdown,
            senderID: senderID,
            senderType: senderType,
            text: text,
            creationTS: creationTS,
            body: body,
            media: media,
            isOffline: isOffline,
            updatedBy: updatedBy,
            updatedTs: updatedTs,
            isDeleted: isDeleted)
    }

    public func attach(clientID: Int) -> JVMessageLocalChange {
        return JVMessageLocalChange(
            ID: ID,
            clientID: clientID,
            chatID: chatID,
            type: type,
            isMarkdown: isMarkdown,
            senderID: senderID,
            senderType: senderType,
            text: text,
            creationTS: creationTS,
            body: body,
            media: media,
            isOffline: isOffline,
            updatedBy: updatedBy,
            updatedTs: updatedTs,
            isDeleted: isDeleted)
    }
}

public final class JVMessageFromClientChange: JVDatabaseModelChange {
    public let ID: Int
    public let channelID: Int
    public let clientID: Int
    public let chatID: Int
    public let text: String
    public let media: JVMessageMediaGeneralChange?

    public override var primaryValue: Int {
        abort()
    }
    
    public override var integerKey: JVDatabaseModelCustomId<Int>? {
        return JVDatabaseModelCustomId(key: "m_id", value: ID)
    }
    
    public init(ID: Int, channelID: Int, clientID: Int, chatID: Int, text: String, media: JVMessageMediaGeneralChange?) {
        self.ID = ID
        self.channelID = channelID
        self.clientID = clientID
        self.chatID = chatID
        self.text = text
        self.media = media
        super.init()
    }
    
    required public init(json: JsonElement) {
        ID = json["msg_id"].intValue
        channelID = json["widget_id"].intValue
        clientID = json["client_id"].intValue
        chatID = json["chat_id"].intValue
        text = json["message"].stringValue
        media = json["media"].parse()
        super.init(json: json)
    }
    
    public func copy(ID: Int) -> JVMessageFromClientChange {
        return JVMessageFromClientChange(
            ID: ID,
            channelID: channelID,
            clientID: clientID,
            chatID: chatID,
            text: text,
            media: media
        )
    }
}

public final class JVMessageFromAgentChange: JVMessageExtendedGeneralChange {
    public let clientID: Int?
    public let senderID: Int
    public let chatID: Int
    public let date: Date?
    public let text: String
    public let media: JVMessageMediaGeneralChange?
    public let updatedBy: Int?
    public let updatedTs: TimeInterval?
    public let isDeleted: Bool

    public override var primaryValue: Int {
        abort()
    }
    
    public init(ID: Int,
         creationTS: TimeInterval,
         clientID: Int?,
         type: String,
         isMarkdown: Bool,
         senderType: String,
         senderID: Int,
         chatID: Int,
         date: Date?,
         text: String,
         body: JVMessageBodyGeneralChange?,
         media: JVMessageMediaGeneralChange?,
         updatedBy: Int?,
         updatedTs: TimeInterval?,
         isDeleted: Bool) {
        self.clientID = clientID
        self.senderID = senderID
        self.chatID = chatID
        self.date = date
        self.text = text
        self.media = media
        self.updatedBy = updatedBy
        self.updatedTs = updatedTs
        self.isDeleted = isDeleted
        
        super.init(
            ID: ID,
            creationTS: creationTS,
            body: body,
            type: type,
            isMarkdown: isMarkdown,
            senderType: senderType
        )
    }
    
    required public init(json: JsonElement) {
        clientID = json["client_id"].int
        senderID = json["from_id"].intValue
        chatID = json["chat_id"].intValue
        date = json["created_ts"].double.flatMap { Date(timeIntervalSince1970: $0) }
        text = json["text"].stringValue
        media = json["media"].parse()
        updatedBy = json["updated_by"].int
        updatedTs = json["updated_ts"].double
        isDeleted = json["deleted"].boolValue
        super.init(json: json)
    }
    
    public override func copy(ID: Int) -> JVMessageFromAgentChange {
        return JVMessageFromAgentChange(
            ID: ID,
            creationTS: creationTS,
            clientID: clientID,
            type: type,
            isMarkdown: isMarkdown,
            senderType: senderType,
            senderID: senderID,
            chatID: chatID,
            date: date,
            text: text,
            body: body,
            media: media,
            updatedBy: updatedBy,
            updatedTs: updatedTs,
            isDeleted: isDeleted)
    }
}

public final class JVMessageStateChange: JVDatabaseModelChange {
    public let localID: String?
    public let globalID: Int
    public let chatID: Int?
    public let agentID: Int?
    public let status: String?
    public let date: Date?
    
    public override var primaryValue: Int {
        abort()
    }
    
    public override var integerKey: JVDatabaseModelCustomId<Int>? {
        if globalID > 0 {
            return JVDatabaseModelCustomId(key: "m_id", value: globalID)
        }
        else {
            return nil
        }
    }
    
    public override var stringKey: JVDatabaseModelCustomId<String>? {
        if let localID = localID {
            return JVDatabaseModelCustomId(key: "m_local_id", value: localID)
        }
        else {
            return nil
        }
    }
    public init(globalID: Int, date: Date?) {
        self.localID = nil
        self.globalID = globalID
        self.chatID = nil
        self.agentID = nil
        self.status = nil
        self.date = date
        super.init()
    }
    
    required public init(json: JsonElement) {
        localID = json["private_id"].string
        globalID = json["msg_id"].intValue
        chatID = json["chat_id"].int
        agentID = json["agent_id"].int
        status = extractStatus(primary: json["statuses"].arrayValue, secondary: json["status"])
        date = nil
        super.init(json: json)
    }
}

public final class JVMessageGeneralSystemChange: JVMessageBaseGeneralChange {
    public let clientID: Int?
    public let chatID: Int
    public let text: String
    public let interactiveID: String?
    public let iconLink: String?
    
    public init(clientID: Int?, chatID: Int, date: Date, text: String, interactiveID: String?, iconLink: String?) {
        self.clientID = clientID
        self.chatID = chatID
        self.text = text
        self.interactiveID = interactiveID
        self.iconLink = iconLink
        super.init(ID: 0, creationTS: date.timeIntervalSince1970, body: nil)
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
    
    public override func copy(ID: Int) -> JVMessageBaseGeneralChange {
        return self
    }
}

public final class JVMessageSendingChange: JVDatabaseModelChange {
    public let localID: String
    public let sendingDate: TimeInterval?
    public let sendingFailed: Bool?
    
    public override var primaryValue: Int {
        abort()
    }
    
    public override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_local_id", value: localID)
    }
    
    public init(localID: String, sendingDate: TimeInterval?, sendingFailed: Bool?) {
        self.localID = localID
        self.sendingDate = sendingDate
        self.sendingFailed = sendingFailed
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVMessageReadChange: JVDatabaseModelChange {
    public let ID: Int
    public let hasRead: Bool
    
    public override var primaryValue: Int {
        abort()
    }
    
    public override var integerKey: JVDatabaseModelCustomId<Int>? {
        return JVDatabaseModelCustomId(key: "m_id", value: ID)
    }
    
    public init(ID: Int, hasRead: Bool) {
        self.ID = ID
        self.hasRead = hasRead
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVMessageReactionChange: JVDatabaseModelChange {
    public let chatID: Int
    public let messageID: Int
    public let emoji: String
    public let fromKind: String
    public let fromID: Int
    public let deleted: Bool
    
    public override var isValid: Bool {
        guard let _ = emoji.jv_valuable else { return false }
        return true
    }

    public override var primaryValue: Int {
        abort()
    }
    
    public override var integerKey: JVDatabaseModelCustomId<Int>? {
        return JVDatabaseModelCustomId(key: "m_id", value: messageID)
    }
    
    required public init(json: JsonElement) {
        chatID = json["chat_id"].intValue
        messageID = json["to_msg_id"].intValue
        emoji = json["icon"].string?.jv_convertToEmojis() ?? String()
        fromKind = json["from"].stringValue
        fromID = json["from_id"].intValue
        deleted = json["deleted"].boolValue
        super.init(json: json)
    }
}

public final class JVMessageTextChange: JVDatabaseModelChange {
    public let UUID: String
    public let text: String
    
    public override var primaryValue: Int {
        abort()
    }
    
    public override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_uid", value: UUID)
    }
    
    public init(UUID: String, text: String) {
        self.UUID = UUID
        self.text = text
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

open class JVMessageSdkClientChange: JVMessageExtendedGeneralChange {
    public let id: Int
    public let localId: String
    public let channelId: Int
    public let clientId: Int
    public let chatId: Int
    public let text: String
    public let date: Date
    public let media: JVMessageMediaGeneralChange?

    open override var primaryValue: Int {
        abort()
    }
    
    public init(id: Int,
         localId: String,
         channelId: Int,
         clientId: Int,
         chatId: Int,
         text: String,
         date: Date,
         media: JVMessageMediaGeneralChange?
    ) {
        self.id = id
        self.localId = localId
        self.channelId = channelId
        self.clientId = clientId
        self.chatId = chatId
        self.text = text
        self.date = date
        self.media = media
        
        super.init(ID: id, creationTS: date.timeIntervalSince1970, body: nil, type: JVMessageType.message.rawValue, isMarkdown: false, senderType: JVSenderType.client.rawValue)
    }
    
    required public init(json: JsonElement) {
        abort()
    }
}

open class JVSdkMessageStatusChange: JVDatabaseModelChange {
    public let id: Int
    public let localId: String
    public let status: JVMessageStatus?
    public let date: Date?
    
    open override var integerKey: JVDatabaseModelCustomId<Int>? {
        return id != 0 && localId.isEmpty
            ? JVDatabaseModelCustomId(key: "m_id", value: id)
            : nil
    }
    
    open override var stringKey: JVDatabaseModelCustomId<String>? {
        return !(localId.isEmpty)
            ? JVDatabaseModelCustomId(key: "m_local_id", value: localId)
            : nil
    }
    
    public init(id: Int = 0, localId: String = "", status: JVMessageStatus?, date: Date? = nil) {
        self.id = id
        self.localId = localId
        self.status = status
        self.date = date
        
        super.init()
    }
    
    required public init(json: JsonElement) {
        abort()
    }
}

public enum JVMessagePropertyUpdate {
    public enum Sender {
        public enum DisplayNameUpdatingLogic {
            case updating(with: String?)
            case withoutUpdate
        }
        
        case client(withId: Int)
        case agent(withId: Int, andDisplayName: DisplayNameUpdatingLogic = .withoutUpdate)
    }
    
    case id(Int)
    case localId(String)
    case text(String)
    case details(String)
    case date(Date)
    case dateFreeze(Date)
    case status(JVMessageStatus)
    case chatId(Int)
    case media(JVMessageMediaGeneralChange)
    case sender(Sender)
    case type(JVMessageType)
    case typeInitial(JVMessageType)
    case isHidden(Bool)
    case isIncoming(Bool)
    case isSendingFailed(Bool)
}

public enum JVSdkMessageAtomChangeInitError: LocalizedError {
    case idIsZero
    case localIdIsEmptyString
    
    public var errorDescription: String? {
        switch self {
        case .idIsZero:
            return "'id' parameter you passed to initializator is equal to zero. It should has some other value."
        case .localIdIsEmptyString:
            return "'localId' parameter you passed to initializator is equal to empty string. It should has some other value."
        }
    }
}

open class JVSdkMessageAtomChange: JVDatabaseModelChange {
    let id: Int
    let localId: String
    public let updates: [JVMessagePropertyUpdate]
    
    public override var primaryValue: Int {
        abort()
    }
    
    open override var integerKey: JVDatabaseModelCustomId<Int>? {
        return id != 0 && localId.isEmpty ? JVDatabaseModelCustomId(key: "m_id", value: id) : nil
    }
    
    open override var stringKey: JVDatabaseModelCustomId<String>? {
        return !localId.isEmpty ? JVDatabaseModelCustomId(key: "m_local_id", value: localId) : nil
    }
    
    public convenience init(id: Int, updates: [JVMessagePropertyUpdate]) throws {
        guard id != 0 else {
            throw JVSdkMessageAtomChangeInitError.idIsZero
        }
        self.init(id: id, localId: String(), updates: updates)
    }
    
    public convenience init(localId: String, updates: [JVMessagePropertyUpdate]) throws {
        guard localId != String() else {
            throw JVSdkMessageAtomChangeInitError.localIdIsEmptyString
        }
        
        if localId.contains(".") {
            let globalId = localId.components(separatedBy: ".").first ?? localId
            self.init(id: globalId.jv_toInt(), localId: String(), updates: updates)
        }
        else {
            self.init(id: 0, localId: localId, updates: updates)
        }
    }
    
    private init(id: Int, localId: String, updates: [JVMessagePropertyUpdate]) {
        self.id = id
        self.localId = localId
        self.updates = updates
        
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

fileprivate func validateMessage(senderType: String, type: String) -> Bool {
    let commonSupported = ["proactive", "email", "message", "transfer", "system", "call", "line", "reminder", "comment", "keyboard", "order"]
    if commonSupported.contains(type) {
        return true
    }
    
    let agentSupported = ["join", "left"]
    if senderType == "agent", agentSupported.contains(type) {
        return true
    }

    return false
}

fileprivate func parseReactions(_ root: JsonElement) -> [JVMessageReaction] {
    return root.ordictValue.compactMap { (emocode, reactors) in
        JVMessageReaction(
            emoji: emocode.jv_convertToEmojis(),
            reactors: reactors.arrayValue.compactMap { item in
                guard let subjectKind = item["type"].string else { return nil }
                guard let subjectID = item["id"].int else { return nil }
                return JVMessageReactor(subjectKind: subjectKind, subjectID: subjectID)
            })
    }
}

public func ==(lhs: JVMessageBaseGeneralChange, rhs: JVMessageBaseGeneralChange) -> Bool {
    if lhs.ID > 0, rhs.ID > 0 {
        return (lhs.ID == rhs.ID && lhs.creationTS == rhs.creationTS)
    }
    else {
        return (lhs.creationTS == rhs.creationTS)
    }
}

public func <(lhs: JVMessageBaseGeneralChange, rhs: JVMessageBaseGeneralChange) -> Bool {
    if lhs.ID > 0, rhs.ID > 0 {
        return (lhs.creationTS < rhs.creationTS || lhs.ID < rhs.ID)
    }
    else {
        return (lhs.creationTS < rhs.creationTS)
    }
}

public func <=(lhs: JVMessageBaseGeneralChange, rhs: JVMessageBaseGeneralChange) -> Bool {
    if lhs.ID > 0, rhs.ID > 0 {
        return (lhs.creationTS <= rhs.creationTS || lhs.ID <= rhs.ID)
    }
    else {
        return (lhs.creationTS <= rhs.creationTS)
    }
}

public func >=(lhs: JVMessageBaseGeneralChange, rhs: JVMessageBaseGeneralChange) -> Bool {
    if lhs.ID > 0, rhs.ID > 0 {
        return (lhs.creationTS >= rhs.creationTS || lhs.ID >= rhs.ID)
    }
    else {
        return (lhs.creationTS >= rhs.creationTS)
    }
}

public func >(lhs: JVMessageBaseGeneralChange, rhs: JVMessageBaseGeneralChange) -> Bool {
    if lhs.ID > 0, rhs.ID > 0 {
        return (lhs.creationTS > rhs.creationTS || lhs.ID > rhs.ID)
    }
    else {
        return (lhs.creationTS > rhs.creationTS)
    }
}

fileprivate func standartizedMessageType(_ type: String) -> String {
    if type == "clientMessage" {
        return "message"
    }
    else {
        return type
    }
}

fileprivate func extractStatus(primary: [JsonElement], secondary: JsonElement) -> String {
    if let item = primary.first(where: { $0["channel_type"] != "rmo" }) {
        return item["status"].stringValue
    }
    
    if let item = primary.first(where: { $0["channel_type"] == "rmo" }) {
        return item["status"].stringValue
    }
    
    return secondary.stringValue
}

public final class JVMessageOutgoingChange: JVDatabaseModelChange {
    let localID: String
    let date: Date
    let clientID: Int?
    let chatID: Int
    let type: String
    let contents: JVMessageContent
    let senderType: String
    let senderID: Int
    
    public init(localID: String,
         date: Date,
         clientID: Int?,
         chatID: Int,
         type: String,
         contents: JVMessageContent,
         senderType: String,
         senderID: Int) {
        self.localID = localID
        self.date = date
        self.clientID = clientID
        self.chatID = chatID
        self.type = type
        self.contents = contents
        self.senderType = senderType
        self.senderID = senderID
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public class JVMessageSdkAgentChange: JVMessageExtendedGeneralChange {
    let agent: JVAgent
    let chat: JVChat
    let creationDate: Date?
    let text: String
    let media: JVMessageMediaGeneralChange?
    let updatedBy: Int?
    let updateDate: Date?
    let isDeleted: Bool

    public override var primaryValue: Int {
        abort()
    }
    
    public init(id: Int,
         agent: JVAgent,
         chat: JVChat,
         text: String,
         body: JVMessageBodyGeneralChange? = nil,
         media: JVMessageMediaGeneralChange? = nil,
         type: JVMessageType,
         isMarkdown: Bool = false,
         creationDate: Date?,
         updatedBy: Int? = nil,
         updateDate: Date? = nil,
         isDeleted: Bool = false
    ) {
        self.agent = agent
        self.chat = chat
        self.creationDate = creationDate
        self.text = text
        self.media = media
        self.updatedBy = updatedBy
        self.updateDate = updateDate
        self.isDeleted = isDeleted
        
        super.init(
            ID: id,
            creationTS: creationDate?.timeIntervalSince1970 ?? TimeInterval.zero,
            body: body,
            type: type.rawValue,
            isMarkdown: isMarkdown,
            senderType: JVSenderType.agent.rawValue
        )
    }
    
    required init(json: JsonElement) {
        abort()
    }
}
