//
//  MessageEntity+Access.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 14.12.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit
import JMRepicKit
import CoreLocation

struct JVMessageContentHash {
    let ID: Int
    let value: Int
    
    func hasChanged(relatedTo anotherHash: JVMessageContentHash?) -> Bool {
        guard let anotherHash = anotherHash else { return false }
        guard ID == anotherHash.ID else { return false }
        return (value != anotherHash.value)
    }
}

struct JVMessageReactor: Codable {
    let subjectKind: String
    let subjectID: Int
}

struct JVMessageReaction: Codable {
    let emoji: String
    var reactors: [JVMessageReactor]
}

enum JVMessageDirection {
    case system
    case incoming
    case outgoing
}

enum JVMessageStatus: String {
    case queued = "queued"
    case sent = "sent"
    case delivered = "delivered"
    case seen = "seen"
    case historic = "received"
    var serverCode: String { rawValue }
}

enum JVMessageDelivery {
    case none
    case sending
    case failed
    case status(JVMessageStatus)
}

enum WaTemplateTextPlacement: Codable {
    case headline
    case body
}

struct WaTemplateVariable: Codable, Equatable {
    let id: Int
    let name: String
    let value: String
    
    init(_ id: Int, _ name: String, _ value: String = "") {
        self.id = id
        self.name = name
        self.value = value
    }
    
    init(id: Int, name: String, value: String) {
        self.id = id
        self.name = name
        self.value = value
    }
}

enum WaTemplateContentPart: Codable {
    case plainText(String)
    case variable(WaTemplateVariable)
}

struct WaTemplateTextComponent: Codable {
    let placement: WaTemplateTextPlacement
    let content: WaTemplateContentPart
}

struct _ChannelByPhone: Codable {
    let channelId: Int
    let phoneNumber: String
    let jointId: String?
    let templatesEnabled: Bool
}

enum WaTemplateHeaderType: Codable {
    case image
    case document
    case video
    case none
}

struct WaTemplatePayload : Codable {
    let toPhoneValue: String
    let fromPhoneValue: _ChannelByPhone
    
    var name: String?
    var languageCode: String?
    var resultedMessage: String?
    
    var headerType: WaTemplateHeaderType?
    
    var components: [WaTemplateTextComponent]?
    
    init(
        toPhoneValue: String,
        fromPhoneValue: _ChannelByPhone,
        name: String? = nil,
        languageCode: String? = nil,
        resultedMessage: String? = nil,
        headerType: WaTemplateHeaderType? = nil,
        components: [WaTemplateTextComponent]? = nil
    ) {
        self.toPhoneValue = toPhoneValue
        self.fromPhoneValue = fromPhoneValue
        self.name = name
        self.languageCode = languageCode
        self.resultedMessage = resultedMessage
        self.headerType = headerType
        self.components = components
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        toPhoneValue = try container.decode(String.self, forKey: .toPhoneValue)
        fromPhoneValue = try container.decode(_ChannelByPhone.self, forKey: .fromPhoneValue)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        languageCode = try container.decodeIfPresent(String.self, forKey: .languageCode)
        resultedMessage = try container.decodeIfPresent(String.self, forKey: .resultedMessage)
        headerType = try container.decodeIfPresent(WaTemplateHeaderType.self, forKey: .headerType)
        components = try container.decodeIfPresent([WaTemplateTextComponent].self, forKey: .components)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toPhoneValue, forKey: .toPhoneValue)
        try container.encode(fromPhoneValue, forKey: .fromPhoneValue)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(languageCode, forKey: .languageCode)
        try container.encodeIfPresent(headerType, forKey: .headerType)
        try container.encodeIfPresent(resultedMessage, forKey: .resultedMessage)
        try container.encodeIfPresent(components, forKey: .components)
    }
    
    enum CodingKeys: String, CodingKey {
        case toPhoneValue
        case fromPhoneValue
        case name
        case languageCode
        case resultedMessage
        case headerType
        case components
    }
}

enum JVMessageTarget: Codable {
    case regular
    case email(fromEmail: String, toEmail: String)
    case sms(fromChannel: Int, toPhone: String)
    case whatsapp(fromChannelName: String, fromPhone: Int, toPhone: String, templateData: WaTemplatePayload?)
    case comment
    
    var supportsFileExchange: Bool {
        switch self {
        case .regular, .email, .whatsapp, .comment:
            return true
        case .sms:
            return false
        }
    }
}

enum JVMessageContent {
    case proactive(message: String)
    case hello(message: String)
    case offline(message: String)
    case text(message: String)
    case comment(message: String)
    case bot(message: String, buttons: [String], markdown: Bool)
    case order(email: String?, phone: String?, subject: String, details: String, button: String)
    case email(from: String, to: String, subject: String, message: String)
    case photo(mime: String, name: String, link: String, dataSize: Int, width: Int, height: Int, title: String?, text: String?)
    case file(mime: String, name: String, link: String, size: Int)
    case transfer(from: AgentEntity, to: AgentEntity)
    case transferDepartment(from: AgentEntity, department: DepartmentEntity, to: AgentEntity)
    case join(assistant: AgentEntity, by: AgentEntity?)
    case left(agent: AgentEntity, kicker: AgentEntity?)
    case call(call: JVMessageBodyCall)
    case task(task: JVMessageBodyTask)
    case conference(conference: JVMessageBodyConference)
    case story(story: JVMessageBodyStory)
    case line
    case contactForm(status: JVMessageBodyContactFormStatus)
    case rateForm(status: JVMessageBodyRateFormStatus)
    case location(CLLocation)
    case chatResolved
    
    public static func makeWith(text: String) -> Self {
        if let url = URL(string: text), let host = url.host, (host.hasPrefix("media") || host.hasPrefix("files")) {
            return .file(mime: "text/plain", name: url.lastPathComponent, link: text, size: 0)
        }
        else {
            return .text(message: text)
        }
    }
    
    var isEditable: Bool {
        switch self {
        case .proactive:
            return false
        case .hello:
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
        case .rateForm:
            return false
        case .chatResolved:
            return false
        case .location:
            return false
        }
    }
    
    var isDeletable: Bool {
        switch self {
        case .proactive:
            return false
        case .hello:
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
        case .rateForm:
            return false
        case .chatResolved:
            return false
        case .location:
            return true
        }
    }
}

struct JVMessageUpdateMeta {
    let agent: AgentEntity
    let date: Date
}

struct JVMessageFlags: OptionSet {
    let rawValue: Int
    static let detachedFromHistory = Self.init(rawValue: 1 << 0)
    static let edgeToHistoryPast = Self.init(rawValue: 1 << 1)
    static let edgeToHistoryFuture = Self.init(rawValue: 1 << 2)
}

extension MessageEntity {
    var UUID: String {
        return m_uid.jv_orEmpty
    }
    
    var flags: JVMessageFlags {
        return JVMessageFlags(rawValue: Int(m_flags))
    }
    
    var ID: Int {
        return Int(m_id)
    }
    
    var localID: String {
        return m_local_id.jv_orEmpty
    }
    
    var date: Date {
        return m_date ?? Date()
    }
    
    var anchorDate: Date {
        let virtualDate = date.dateBySet(hour: nil, min: nil, secs: nil, ms: self.ID % 1000)
        return virtualDate ?? date
    }
    
    var clientID: Int {
        return Int(m_client_id)
    }
    
    var referralSource: ReferralSourceEntity? {
        return m_referral_source
    }
    
    var client: ClientEntity? {
        return m_client
    }
    
    var chatID: Int {
        return Int(m_chat_id)
    }
    
    var target: JVMessageTarget {
        guard let source = m_target, !source.isEmpty
        else {
            return .regular
        }
        
        do {
            let result = try JSONDecoder().decode(JVMessageTarget.self, from: source)
            return result
        }
        catch {
            return .regular
        }
    }
    
    var direction: JVMessageDirection {
        if renderingType.belonging == .hidden {
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
    
    var logicalType: MessageType {
        return MessageType.by(name: m_type.jv_orEmpty) ?? .message
    }
    
    var renderingType: MessageType {
        if wasDeleted {
            return .message
        }
        else {
            return logicalType
        }
    }
    
    var channel: ChannelEntity? {
        return m_channel
    }
    
    var content: JVMessageContent {
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
                    height: Int(media.originalSize.height),
                    title: media.m_title,
                    text: media.m_text
                )
            }
            else if media.type == .location {
                let location = CLLocation(latitude: media.m_latitude, longitude: media.m_longitude)
                return .location(location)
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
        
        switch renderingType {
        case .proactive:
            return .proactive(
                message: m_text.jv_orEmpty
            )
            
        case .hello:
            return .hello(
                message: m_text.jv_orEmpty
            )

        case .offline:
            return .offline(
                message: m_text.jv_orEmpty
            )
            
        case .email:
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
            
        case .message, .keyboard:
            if let call = m_body?.call {
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
            
        case .transfer:
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
            
        case .join:
            if let joinedAgent = m_sender_agent {
                return .join(
                    assistant: joinedAgent,
                    by: m_body?.invite?.by
                )
            }
            else {
                assertionFailure()
            }

        case .left:
            if let leftAgent = m_sender_agent {
                return .left(
                    agent: leftAgent,
                    kicker: m_body?.invite?.by
                )
            }
            else {
                assertionFailure()
            }
            
        case .system:
            return .text(
                message: m_text.jv_orEmpty
            )
            
        case .call:
            if let call = m_body?.call {
                return .call(
                    call: call
                )
            }

        case .line:
            return .line

        case .reminder:
            if let task = m_body?.task {
                return .task(
                    task: task
                )
            }
            
        case .comment:
            return .comment(
                message: m_text.jv_orEmpty
            )
            
        case .order:
            if let order = m_body?.order {
                return .order(
                    email: order.email,
                    phone: order.phone,
                    subject: order.subject,
                    details: order.text,
                    button: loc["Chat.Order.Call.Button"])
            }
            
        case .contactForm:
            let status = JVMessageBodyContactFormStatus(rawValue: rawText) ?? .inactive
            return .contactForm(status: status)
            
        case .chatRate:
            let status = JVMessageBodyRateFormStatus(rawValue: rawDetails) ?? .initial
            return .rateForm(status: status)
            
        case .chatResolved:
            return .chatResolved
        default:
            break
        }
        
        return .text(
            message: m_text.jv_orEmpty
        )
    }
    
    var isAutomatic: Bool {
        if case .proactive = content {
            return true
        }
        else {
            return false
        }
    }
    
    var quotedMessage: MessageEntity? {
        return m_quoted_message
    }
    
    var sender: JVDisplayable? {
        return m_sender_agent ?? m_sender_client ?? client
    }
    
    var senderClient: ClientEntity? {
        return m_sender_client
    }
    
    var senderAgent: AgentEntity? {
        if case .call(let call) = content {
            return call.agent
        }
        else {
            return m_sender_agent
        }
    }
    
    var senderBotFlag: Bool {
        return m_sender_bot_flag
    }
    
    var senderBot: BotEntity? {
        return m_sender_bot
    }
    
    func relativeSenderDisplayName() -> String? {
        if senderBotFlag {
            return "bot"
        }
        else if let sender = sender, sender.jv_isValid {
            return (renderingType.belonging == .hidden ? nil : sender.displayName(kind: .relative))
        }
        else {
            return nil
        }
    }
    
    var rawText: String {
        return m_text.jv_orEmpty
    }
    
    var rawDetails: String {
        return m_details.jv_orEmpty
    }
    
    var text: String {
        guard !(wasDeleted) else {
            return loc["JV_ChatTimeline_MessageStatus_Deleted", "Message.Deleted"]
        }
        
        if case .whatsapp(_, _, _, let payload) = target, let payload = payload, let media = m_media {
            return "[wb_media](" + (media.fullURL?.absoluteString ?? "") + ")\n" + payload.resultedMessage.jv_orEmpty
        }

        
        if let media = m_media {
            if media.type == .location {
                return loc["Message.Preview.Location"]
            }
            else if let name = media.name {
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
    
    var taskStatus: JVMessageBodyTaskStatus {
        if case .task(let task) = content {
            return m_body?.status.flatMap(JVMessageBodyTaskStatus.init) ?? task.status
        }
        else {
            return .unknown
        }
    }
    
    var contentHash: JVMessageContentHash {
        var hasher = Hasher()
        
        hasher.combine(renderingType.exportableName())
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
    
    var isMarkdown: Bool {
        return m_is_markdown
    }
    
    func iconContent() -> UIImage? {
        switch content {
        case .proactive,
             .hello,
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
             .task,
             .bot,
             .location,
             .order,
             .contactForm,
             .rateForm,
             .chatResolved:
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
        case .conference:
            return UIImage(named: "preview_conf")
        }
    }

    func contextImageURL(transparent: Bool) -> JMRepicItem? {
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
    
    var status: JVMessageStatus? {
        return JVMessageStatus(rawValue: m_status.jv_orEmpty)
    }
    
    var delivery: JVMessageDelivery {
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
    
    var interactiveID: String? {
        return m_interactive_id
    }
    
    var hasRead: Bool {
        return m_has_read
    }
    
    var sentByMe: Bool {
        if direction != .outgoing {
            return false
        }
        else {
            return (m_sender_agent?.isMe == true)
        }
    }
    
    var media: MessageMediaEntity? {
        return m_media
    }
    
    var call: JVMessageBodyCall? {
        return m_body?.call
    }

    var order: JVMessageBodyOrder? {
        return m_body?.order
    }

    var task: JVMessageBodyTask? {
        return m_body?.task
    }
    
    var iconURL: URL? {
        if let link = m_icon_link?.jv_valuable {
            return URL(string: link)
        }
        else {
            return nil
        }
    }
    
    var isOffline: Bool {
        return m_is_offline
    }
    
    var isHidden: Bool {
        return m_is_hidden
    }
    
    var wasDeleted: Bool {
        return m_was_deleted
    }
    
    var updatedMeta: JVMessageUpdateMeta? {
        guard let agent = m_updated_agent else { return nil }
        let date = Date(timeIntervalSince1970: m_updated_timepoint)
        return JVMessageUpdateMeta(agent: agent, date: date)
    }
    
    var reactions: [JVMessageReaction] {
        guard
            let data = m_reactions,
            let items = try? PropertyListDecoder().decode([JVMessageReaction].self, from: data)
            else { return [] }
        
        return items
    }
    
    var buttons: [String] {
        return m_body?.buttons ?? []
    }
    
    var hasIdentity: Bool {
        return (self.ID > 0 || !(localID.isEmpty))
    }
    
    func obtainObjectToCopy() -> Any? {
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
    
    func correspondsTo(chat: ChatEntity) -> Bool {
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
    
    var isUnsent: Bool {
        guard direction == .outgoing else { return false }
        guard self.ID == 0 else { return false }
        return true
    }
    
    var isQuotable: Bool {
        if wasDeleted {
            return false
        }
        
        switch content {
        case .comment:
            return false
        case _ where isUnsent:
            return false
        default:
            return true
        }
    }
    
    /**
     Some extra private methods for <func correspondsTo(chat: JVChat) Bool>
     to make the stacktrace more readable for debug purpose
     */
    
    private func _correspondsTo_getSelfChatId() -> Int? {
        return jv_isValid ? chatID : nil
    }
    
    private func _correspondsTo_getSelfClient() -> ClientEntity? {
        return jv_isValid ? client : nil
    }
    
    private func _correspondsTo_getChat(chat: ChatEntity) -> ChatEntity? {
        return jv_validate(chat)
    }
    
    private func _correspondsTo_getChatClient(chat: ChatEntity) -> ClientEntity? {
        return chat.jv_isValid ? jv_validate(chat.client) : nil
    }
    
    func canUpgradeStatus(to newStatus: String) -> Bool {
        return (m_status != newStatus)
    }
}
