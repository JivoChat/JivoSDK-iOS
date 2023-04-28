//
//  Message+Access.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 14.12.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
import JMCodingKit
import JMRepicKit

public struct JVMessageContentHash {
    public let ID: Int
    public let value: Int
    
    public init(ID: Int, value: Int) {
        self.ID = ID
        self.value = value
    }
    
    public func hasChanged(relatedTo anotherHash: JVMessageContentHash?) -> Bool {
        guard let anotherHash = anotherHash else { return false }
        guard ID == anotherHash.ID else { return false }
        return (value != anotherHash.value)
    }
}

public struct JVMessageReactor: Codable {
    public let subjectKind: String
    public let subjectID: Int
    
    public init(subjectKind: String, subjectID: Int) {
        self.subjectKind = subjectKind
        self.subjectID = subjectID
    }
}

public struct JVMessageReaction: Codable {
    public let emoji: String
    public var reactors: [JVMessageReactor]
    
    public init(emoji: String, reactors: [JVMessageReactor]) {
        self.emoji = emoji
        self.reactors = reactors
    }
}

public enum JVMessageDirection {
    case system
    case incoming
    case outgoing
}

public enum JVMessageStatus: String {
    case queued = "queued"
    case sent = "sent"
    case delivered = "delivered"
    case seen = "seen"
    case historic = "received"
    var serverCode: String { rawValue }
}

public enum JVMessageDelivery {
    case none
    case sending
    case failed
    case status(JVMessageStatus)
}

public enum JVMessageType: String {
    case message = "message"
    case system = "system"
    case contactForm = "contact_form"
}

public enum JVMessageContent {
    case proactive(message: String)
    case offline(message: String)
    case text(message: String)
    case comment(message: String)
    case bot(message: String, buttons: [String], markdown: Bool)
    case order(email: String?, phone: String?, subject: String, details: String, button: String)
    case email(from: String, to: String, subject: String, message: String)
    case photo(mime: String, name: String, link: String, dataSize: Int, width: Int, height: Int)
    case file(mime: String, name: String, link: String, size: Int)
    case transfer(from: JVAgent, to: JVAgent)
    case transferDepartment(from: JVAgent, department: JVDepartment, to: JVAgent)
    case join(assistant: JVAgent, by: JVAgent?)
    case left(agent: JVAgent, kicker: JVAgent?)
    case call(call: JVMessageBodyCall)
    case task(task: JVMessageBodyTask)
    case conference(conference: JVMessageBodyConference)
    case story(story: JVMessageBodyStory)
    case line
    case contactForm(status: JVMessageBodyContactFormStatus)
    
    public static func makeWith(text: String) -> Self {
        if let url = URL(string: text), let host = url.host, host.contains(".jivo"), (host.hasPrefix("media") || host.hasPrefix("files")) {
            return .file(mime: "text/plain", name: url.lastPathComponent, link: text, size: 0)
        }
        else {
            return .text(message: text)
        }
    }
    
    public var isEditable: Bool {
        switch self {
        case .proactive:
            return false
        case .offline:
            return false
        case .text:
            return true
        case .comment:
            return true
        case .email:
            return false
        case .photo:
            return false
        case .file:
            return false
        case .transfer:
            return false
        case .transferDepartment:
            return false
        case .join:
            return false
        case .left:
            return false
        case .call:
            return false
        case .task:
            return false
        case .line:
            return false
        case .conference:
            return false
        case .story:
            return false
        case .bot:
            return false
        case .order:
            return false
        case .contactForm:
            return false
        }
    }
    
    public var isDeletable: Bool {
        switch self {
        case .proactive:
            return false
        case .offline:
            return true
        case .text:
            return true
        case .comment:
            return true
        case .email:
            return false
        case .photo:
            return true
        case .file:
            return true
        case .transfer:
            return false
        case .transferDepartment:
            return false
        case .join:
            return false
        case .left:
            return false
        case .call:
            return false
        case .task:
            return false
        case .line:
            return false
        case .conference:
            return false
        case .story:
            return false
        case .bot:
            return false
        case .order:
            return false
        case .contactForm:
            return false
        }
    }
}

public struct JVMessageUpdateMeta {
    let agent: JVAgent
    let date: Date
}

extension JVMessage {
    public var UUID: String {
        return m_uid.jv_orEmpty
    }
    
    public var ID: Int {
        return Int(m_id)
    }
    
    public var localID: String {
        return m_local_id.jv_orEmpty
    }
    
    public var date: Date {
        return m_date ?? Date()
    }
    
    public var clientID: Int {
        return Int(m_client_id)
    }
    
    public var client: JVClient? {
        return m_client
    }
    
    public var chatID: Int {
        return Int(m_chat_id)
    }
    
    public var direction: JVMessageDirection {
        if ["system", "transfer", "join", "left", "line", "reminder"].contains(type) {
            return .system
        }
        else if call?.type == JVMessageBodyCallType.incoming {
            return .incoming
        }
        else if m_is_incoming {
            return .incoming
        }
        else {
            return .outgoing
        }
    }
    
    public var type: String {
        guard !(m_was_deleted) else {
            return "message"
        }
        
        return m_type.jv_orEmpty
    }
    
    public var isSystemLike: Bool {
        switch type {
        case "proactive":
            return false
        case "email":
            return false
        case "message":
            return false
        case "transfer":
            return true
        case "join":
            return true
        case "left":
            return true
        case "system":
            return true
        case "call":
            return true
        case "line":
            return true
        case "reminder":
            return true
        case "comment":
            return false
        case "keyboard":
            return false
        case "order":
            return false
        default:
            return true
        }
    }
    
    public var content: JVMessageContent {
        switch type {
        case "proactive":
            return .proactive(
                message: m_text.jv_orEmpty
            )
            
        case "offline":
            return .offline(
                message: m_text.jv_orEmpty
            )
            
        case "email":
            if let email = m_body?.email {
                return .email(
                    from: email.from,
                    to: email.to,
                    subject: email.subject,
                    message: m_text.jv_orEmpty
                )
            }
            else {
                assertionFailure()
            }
            
        case "message":
            if let media = m_media {
                let link = (media.fullURL ?? media.thumbURL)?.absoluteString ?? ""
                let name = media.name ?? link
                
                if media.type == .photo {
                    return .photo(
                        mime: media.mime,
                        name: name,
                        link: link,
                        dataSize: media.dataSize,
                        width: Int(media.originalSize.width),
                        height: Int(media.originalSize.height)
                    )
                }
                else if let conference = media.conference {
                    return .conference(
                        conference: conference
                    )
                }
                else if let story = media.story {
                    return .story(
                        story: story
                    )
                }
                else {
                    return .file(
                        mime: media.mime,
                        name: name,
                        link: link,
                        size: media.dataSize
                    )
                }
            }
            else if let call = m_body?.call {
                return .call(
                    call: call
                )
            }
            else if let task = m_body?.task {
                return .task(
                    task: task
                )
            }
            else if senderBotFlag, let buttons = m_body?.buttons, !buttons.isEmpty {
                let caption = m_body?.text?.jv_valuable ?? text
                return .bot(message: caption, buttons: buttons, markdown: m_is_markdown)
            }
            else {
                return .text(
                    message: text
                )
            }
            
        case "transfer":
            if let transferFrom = m_sender_agent, let department = m_body?.transfer?.department, let transferTo = m_body?.transfer?.agent {
                return .transferDepartment(
                    from: transferFrom,
                    department: department,
                    to: transferTo
                )
            }
            else if let transferFrom = m_sender_agent, let transferTo = m_body?.transfer?.agent {
                return .transfer(
                    from: transferFrom,
                    to: transferTo
                )
            }
            else {
                assertionFailure()
            }
            
        case "join":
            if let joinedAgent = m_sender_agent {
                return .join(
                    assistant: joinedAgent,
                    by: m_body?.invite?.by
                )
            }
            else {
                assertionFailure()
            }

        case "left":
            if let leftAgent = m_sender_agent {
                return .left(
                    agent: leftAgent,
                    kicker: m_body?.invite?.by
                )
            }
            else {
                assertionFailure()
            }
            
        case "system":
            return .text(
                message: m_text.jv_orEmpty
            )
            
        case "call":
            if let call = m_body?.call {
                return .call(
                    call: call
                )
            }

        case "line":
            return .line

        case "reminder":
            if let task = m_body?.task {
                return .task(
                    task: task
                )
            }
            
        case "comment":
            return .comment(
                message: m_text.jv_orEmpty
            )
            
        case "order":
            if let order = m_body?.order {
                return .order(
                    email: order.email,
                    phone: order.phone,
                    subject: order.subject,
                    details: order.text,
                    button: loc["Chat.Order.Call.Button"])
            }
            
        case "contact_form":
            let status = JVMessageBodyContactFormStatus(rawValue: rawText) ?? .inactive
            return .contactForm(status: status)

        default:
            break
//            assertionFailure()
        }
        
        return .text(
            message: m_text.jv_orEmpty
        )
    }
    
    public var isAutomatic: Bool {
        if case .proactive = content {
            return true
        }
        else {
            return false
        }
    }
    
    public var sender: JVDisplayable? {
        return m_sender_agent ?? m_sender_client ?? client
    }
    
    public var senderClient: JVClient? {
        return m_sender_client
    }
    
    public var senderAgent: JVAgent? {
        if case .call(let call) = content {
            return call.agent
        }
        else {
            return m_sender_agent
        }
    }
    
    public var senderBotFlag: Bool {
        return m_sender_bot_flag
    }
    
    public var senderBot: JVBot? {
        return m_sender_bot
    }
    
    public func relativeSenderDisplayName() -> String? {
        if senderBotFlag {
            return "bot"
        }
        else if let sender = sender, sender.jv_isValid {
            return isSystemLike ? nil : sender.displayName(kind: .relative)
        }
        else {
            return nil
        }
    }
    
    public var rawText: String {
        return m_text.jv_orEmpty
    }
    
    public var rawDetails: String {
        return m_details.jv_orEmpty
    }
    
    public var text: String {
        guard !(wasDeleted) else {
            return loc["Message.Deleted"]
        }
        
        if let media = m_media {
            if let name = media.name {
                return name
            }
            else if let link = media.fullURL?.absoluteString {
                return link
            }

            return String()
        }
        else {
            if let text = m_text?.jv_valuable {
                return text
            }
            else if let subject = m_body?.email?.subject {
                return subject
            }
            else if let details = m_body?.order?.text {
                return details
            }
            else if let text = m_body?.text?.jv_valuable {
                return text
            }

            return String()
        }
    }
    
    public var taskStatus: JVMessageBodyTaskStatus {
        if case .task(let task) = content {
            return m_body?.status.flatMap(JVMessageBodyTaskStatus.init) ?? task.status
        }
        else {
            return .unknown
        }
    }
    
    public var contentHash: JVMessageContentHash {
        var hasher = Hasher()
        
        hasher.combine(type)
        hasher.combine(text)
        
        if let media = m_media {
            hasher.combine(media.dataSize)
            hasher.combine(media.originalSize.width)
            hasher.combine(media.originalSize.height)
        }
        
        return JVMessageContentHash(
            ID: Int(m_id),
            value: hasher.finalize()
        )
    }
    
    public var isMarkdown: Bool {
        return m_is_markdown
    }
    
    public func iconContent() -> UIImage? {
        switch content {
        case .proactive,
             .offline,
             .text,
             .comment,
             .transfer,
             .transferDepartment,
             .join,
             .left,
             .photo,
             .file,
             .line,
             .bot,
             .order,
             .contactForm:
            return nil
            
        case .story:
            return UIImage(named: "preview_ig")

        case .email:
            return UIImage(named: "preview_email")

        case .call(let call):
            switch call.type {
            case .callback:
                return UIImage(named: "preview_call_out")
            case .outgoing:
                return UIImage(named: "preview_call_out")
            case .incoming:
                return UIImage(named: "preview_call_in")
            case .unknown:
                return nil
            }

        case .task:
            return nil
            
        case .conference:
            return UIImage(named: "preview_conf")
        }
    }

    public func contextImageURL(transparent: Bool) -> JMRepicItem? {
        switch content {
        case .transfer(let inviter, let assistant) where assistant.isMe:
            return inviter.repicItem(transparent: transparent, scale: nil)

        case .transfer(_, let assistant):
            return assistant.repicItem(transparent: transparent, scale: nil)

        case .join(let assistant, _):
            return assistant.repicItem(transparent: transparent, scale: nil)

        case .left:
            return nil

        default:
            break
        }

        guard let link = m_icon_link?.jv_valuable else { return nil }
        return URL(string: link).flatMap(JMRepicItemSource.remote).flatMap {
            JMRepicItem(backgroundColor: nil, source: $0, scale: 1.0, clipping: .dual)
        }
    }
    
    public var status: JVMessageStatus? {
        switch m_status {
        case "sent":
            return JVMessageStatus.sent
        case "delivered":
            return JVMessageStatus.delivered
        case "seen":
            return JVMessageStatus.seen
        case "queued":
            return JVMessageStatus.queued
        default:
            return nil
        }
    }
    
    public var delivery: JVMessageDelivery {
        if direction != .outgoing {
            return .none
        }
        else if m_id == 0, m_local_id?.jv_valuable != nil {
            return m_sending_failed ? .failed : .sending
        }
        else if let status = status {
            return .status(status)
        }
        else {
            return .none
        }
    }
    
    public var interactiveID: String? {
        return m_interactive_id
    }
    
    public var hasRead: Bool {
        return m_has_read
    }
    
    public var sentByMe: Bool {
        if direction != .outgoing {
            return false
        }
        else {
            return (m_sender_agent?.isMe == true)
        }
    }
    
    public var media: JVMessageMedia? {
        return m_media
    }
    
    public var call: JVMessageBodyCall? {
        return m_body?.call
    }

    public var order: JVMessageBodyOrder? {
        return m_body?.order
    }

    public var task: JVMessageBodyTask? {
        return m_body?.task
    }
    
    public var iconURL: URL? {
        if let link = m_icon_link?.jv_valuable {
            return URL(string: link)
        }
        else {
            return nil
        }
    }
    
    public var isOffline: Bool {
        return m_is_offline
    }
    
    public var isHidden: Bool {
        return m_is_hidden
    }
    
    public var wasDeleted: Bool {
        return m_was_deleted
    }
    
    public var updatedMeta: JVMessageUpdateMeta? {
        guard let agent = m_updated_agent else { return nil }
        let date = Date(timeIntervalSince1970: m_updated_timepoint)
        return JVMessageUpdateMeta(agent: agent, date: date)
    }
    
    public var reactions: [JVMessageReaction] {
        guard
            let data = m_reactions,
            let items = try? PropertyListDecoder().decode([JVMessageReaction].self, from: data)
            else { return [] }
        
        return items
    }
    
    public var buttons: [String] {
        return m_body?.buttons ?? []
    }
    
    public var hasIdentity: Bool {
        return (ID > 0 || !(localID.isEmpty))
    }
    
    public func obtainObjectToCopy() -> Any? {
        if let media = media {
            return media.fullURL ?? media.thumbURL
        }
        else if let call = call {
            return call.phone
        }
        else {
            return text
        }
    }
    
    public func correspondsTo(chat: JVChat) -> Bool {
        if let client = _correspondsTo_getSelfClient() {
            let chatClient = _correspondsTo_getChatClient(chat: chat)
            return (client.ID == chatClient?.ID)
        }
        else {
            let selfChatId = _correspondsTo_getSelfChatId()
            let chatId = _correspondsTo_getChat(chat: chat)?.ID
            return (selfChatId == chatId)
        }
    }
    
    /**
     Some extra private methods for <func correspondsTo(chat: JVChat) Bool>
     to make the stacktrace more readable for debug purpose
     */
    
    private func _correspondsTo_getSelfChatId() -> Int? {
        return jv_isValid ? chatID : nil
    }
    
    private func _correspondsTo_getSelfClient() -> JVClient? {
        return jv_isValid ? client : nil
    }
    
    private func _correspondsTo_getChat(chat: JVChat) -> JVChat? {
        return jv_validate(chat)
    }
    
    private func _correspondsTo_getChatClient(chat: JVChat) -> JVClient? {
        return chat.jv_isValid ? jv_validate(chat.client) : nil
    }
    
    public func canUpgradeStatus(to newStatus: String) -> Bool {
        return (m_status != newStatus)
    }
}

public class JVSDKMessageOfflineChange: JVDatabaseModelChange {
    public let localId = JVSDKMessageOfflineChange.id
    public let date = Date()
    public let type = "offline"
    
    public let content: JVMessageContent
    
    public override var primaryValue: Int {
        abort()
    }
    
    public override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId<String>(key: "m_local_id", value: localId)
    }
    
    public init(message: String) {
        content = .offline(message: message)
        
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

extension JVSDKMessageOfflineChange {
    public static let id = "OFFLINE_MESSAGE"
}
