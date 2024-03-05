//
//  SdkChatProto.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 15.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import JMCodingKit
import SwiftMime

protocol ISdkChatProto {
    func requestRecentActivity(siteId: Int, channelId: String, clientId: String) -> INetworking
    func requestMessageHistory(before anchorMessageId: Int?)
    func sendMessage(_ message: JVMessage, mime: String)
    func sendRateInfo(chatID: String, rate: String, comment: String?)
    func sendMessageAck(id: Int, date: Date)
    func sendTyping(text: String)
}

enum SdkChatProtoEventSubject: IProtoEventSubject {
    case recentActivity(ProtoEventSubjectPayload.RecentActivity)
}

extension ProtoTransactionKind {
    enum ChatNamespace: String {
        case user
        case message
    }
    
    static func chat(_ namespace: ChatNamespace) -> ProtoTransactionKind {
        return caseFor(namespace)
    }
}

enum SdkChatProtoUserSubject: IProtoEventSubject {
    case switchingDataReceivingMode
    case statusUpdated(to: String, ofUserWithId: String)
    case nameUpdated(to: String, ofUserWithId: String)
    case titleUpdated(to: String, ofUserWithId: String)
    case photoUpdated(to: String, ofUserWithId: String)
}

enum SdkChatProtoMessageSubject: IProtoEventSubject {
    case delivered(messageWithId: Int, andPrivateId: String, at: Date)
    case received(messageWithId: Int, data: String?, andMedia: SdkChatProtoAtomMessageMedia? = nil, fromUserWithId: String, sentAt: Date)
    case seen(messageWithId: Int, andDate: Date)
    case rate
}

struct SdkChatProtoAtomMessageMedia {
    let name: String
    let mime: String
    let type: JVMessageMediaType
    let link: String
}

enum SdkChatProtoMessageMediaMimeType {
    case text(ext: String? = nil)
    case image(ext: String)
    case application(ext: String)
    case audio(ext: String)
    case video(ext: String)
    
    init?(string: String) {
        let splitedString = string.split(separator: "/")
        
        guard
            let mime = splitedString.first,
            let ext = splitedString.last.flatMap(String.init)
        else { return nil }
        
        switch mime {
        case "text": self = .text()
        case "image": self = .image(ext: ext)
        case "application": self = .application(ext: ext)
        case "audio": self = .audio(ext: ext)
        case "video": self = .video(ext: ext)
        default: return nil
        }
    }
}

extension JVMessageMediaType {
    init(mimeType: SdkChatProtoMessageMediaMimeType) {
        switch mimeType {
        case .text: self = .document
        case .image: self = .photo
        default: self = .document
        }
    }
    
    var rawValue: String {
        switch self {
        case .audio: return "audio"
        case .comment: return "comment"
        case .contact: return "contact"
        case .document: return "document"
        case .location: return "location"
        case .photo: return "photo"
        case .video: return "video"
        case .voice: return "voice"
        case .sticker: return "sticker"
        case .conference: return "conference"
        case .story: return "story"
        case .unknown: return "unknown"
        }
    }
}

final class SdkChatProto: BaseProto, ISdkChatProto {
    // MARK: - Public methods
    
    // MARK: Encoding
    
    func requestRecentActivity(siteId: Int, channelId: String, clientId: String) -> INetworking {
        let options = RestRequestOptions(
            behavior: .regular,
            method: .get,
            headers: [
                "x-jv-client-id": clientId
            ],
            query: Array(),
            body: .omit
        )
        
        return networking.send(
            output: .rest(
                kindID: ProtoEventSubjectPayload.RecentActivity.kindId,
                target: .build(
                    scope: .chatServer,
                    path: "client/\(siteId)/\(channelId)/messages"
                ),
                options: options,
                contextID: networking.flushContext()
            ),
            caching: .auto)
    }
    
    func requestMessageHistory(before anchorMessageId: Int?) {
        networking.send(
            output: .atom(
                type: "atom/me.history",
                context: nil,
                id: nil,
                data: anchorMessageId.flatMap(String.init)
            ),
            caching: .enabled)
    }
    
    func sendMessage(_ message: JVMessage, mime: String) {
        networking.send(
            output: .atom(
                type: mime,
                context: message.localID,
                id: nil,
                data: message.media.flatMap { $0.m_full_link } ?? message.text
            ),
            caching: .disabled)
        
        let messageLocalId = message.localID
        let messageText = message.text
        journal {"Sending the message[\(messageText)] under privateId[\(messageLocalId)]"}
    }
    
    func sendMessageAck(id: Int, date: Date) {
        networking.send(
            output: .atom(
                type: "atom/message.ack",
                context: nil,
                id: nil,
                data: "\(id).\(Int(date.timeIntervalSince1970))"
            ),
            caching: .disabled)
    }
    
    func sendTyping(text: String) {
        networking.send(
            output: .atom(
                type: "atom/user.typing",
                context: nil,
                id: nil,
                data: text
            ),
            caching: .disabled)
    }
    
    func sendRateInfo(chatID: String, rate: String, comment: String?) {
        let array: [String: String] = ["rate": rate, "comment": comment.jv_orEmpty]
        
        guard let payload = try? JSONEncoder().encode(array) else { return }
        
        _ = networking.send(
            output: .atom(
                type: "atom/chat.rate",
                context: nil,
                id: chatID,
                data: String(data: payload, encoding: .utf8).jv_orEmpty
            ),
            caching: .auto
        )
    }
    
//    func requestUploading(provider: String, file: HTTPFileConfig, callback: @escaping (HTTPUploadAck) -> Void) {
//        guard let endpoint = userContext?.connectionConfig?.apiHost else {
//            return journal {"{ChatProto} ::requestUploading Can not request file upload from API: apiHost in SDK connection config is nil."}
//        }
//
//        let context = CommonFileContext(file: file, callback: callback)
//        let contextID = networking.contextual(object: context).flushContext()
//        userContext?.havingAccess { [unowned self] in
//            let options = RestRequestOptions(
//                behavior: .regular,
//                target: .build(
//                    service: endpoint,
//                    path: provider
//                ),
//                method: .get,
//                headers: networkingHelper.generateHeaders(auth: .apply, contentType: nil),
//                query: file.params,
//                body: .omit
//            )
//
//            networking.send(
//                output: .rest(
//                    kindID: ProtoEventSubjectPayload.FileCredentials.kindID,
//                    options: options,
//                    contextID: contextID
//                ),
//                caching: .auto)
//            }
//    }
    
//    func metaFor(fileWithURL fileUrl: URL, completion: @escaping () -> Void) {
//        let options = RestRequestOptions(
//            behavior: .regular,
//            target: .url(fileUrl.absoluteString),
//            method: .head,
//            headers: [:],
//            query: Array(),
//            body: .omit
//        )
//
//        networking.send(
//            output: .rest(
//                kindID: ProtoEventSubjectPayload.FileMeta.kindId,
//                options: options,
//                contextID: networking.flushContext()
//            ),
//            caching: .auto)
//    }
//
//    // MARK: - Private methods
//
//    // MARK: BaseProto methods
//
//    override func decodeToSubject(event: NetworkingSubject) -> IProtoEventSubject? {
//        switch event {
//        case let .rest(.response(ProtoEventSubjectPayload.FileMeta.kindId, _, response)):
//            return decodeFileMetaResponse(status: response.status, headers: response.headers)
//        default:
//            return super.decodeToSubject(event: event)
//        }
//    }
//
    override func decodeToSubject(event: NetworkingSubject) -> IProtoEventSubject? {
        switch event {
        case NetworkingSubject.rest(.response(ProtoEventSubjectPayload.RecentActivity.kindId, _, let response)):
            return decodeRecentActivity(response)
        default:
            return super.decodeToSubject(event: event)
        }
    }

    override func decodeToBundle(event: NetworkingSubject) -> ProtoEventBundle? {
        switch event {
        case NetworkingSubject.socket(.payload(.atom("atom/user", let model))):
            return decodeUser(model)
        case NetworkingSubject.socket(.payload(.atom("atom/user.name", let model))):
            return decodeUserName(model)
        case NetworkingSubject.socket(.payload(.atom("atom/user.title", let model))):
            return decodeUserTitle(model)
        case let NetworkingSubject.socket(.payload(.atom("atom/user.photo", model))):
            return decodeUserPhoto(model)
        case let NetworkingSubject.socket(.payload(.atom("atom/message.id", model))):
            return decodeMessageId(model)
        case let NetworkingSubject.socket(.payload(.atom("atom/message.ack", model))):
            return decodeMessageAck(model)
        case let NetworkingSubject.socket(.payload(.atom("atom/chat.rate", model))):
            return decodeChatRate(model)
        case NetworkingSubject.socket(.payload(.atom(let type, let model))) where doesMessageContainMediaLink(model["data"].stringValue):
            return decodeMessageAsMediaLink(model, type: type)
        case NetworkingSubject.socket(.payload(.atom(let type, let model))) where doesMessageContainMediaMarkdown(model["data"].stringValue, json: model):
            return decodeMessageAsMediaMarkdown(model, type: type)
        case NetworkingSubject.socket(.payload(.atom("text/plain", let model))):
            return decodeMessageTextPlain(model)
        default:
            return super.decodeToBundle(event: event)
        }
    }
    
    private func decodeRecentActivity(_ response: NetworkingSubRestEvent.Response) -> SdkChatProtoEventSubject {
        let meta = ProtoEventSubjectPayload.RecentActivity(
            status: response.status,
            body: .init(
                latestMessageId: response.body["result"]["messages"]
                    .arrayValue
                    .compactMap { $0["msg_id"].int }
                    .max()
            )
        )
        
        return .recentActivity(meta)
    }
    
    private func doesMessageContainMediaLink(_ link: String) -> Bool {
        guard let host = URL(string: link)?.host
        else {
            return false
        }
        
        return (host.hasPrefix("media") || host.hasPrefix("files"))
    }
    
    private func doesMessageContainMediaMarkdown(_ markdown: String, json: JsonElement) -> Bool {
        guard let userId = json["from"].string,
              (userId as NSString).integerValue < 0
        else {
            return false
        }

        if markdown.hasPrefix("![") {
            return markdown.hasSuffix(")")
        }
        else {
            return false
        }
    }
    
//    private func fileNameFor(headerContentDispositionValue headerValue: String) -> String? {
//        let fileNameRange = headerValue.range(of: "filename=\"(.*?)\"", options: .regularExpression)
//        let fileName = fileNameRange.flatMap {
//            headerValue[$0.lowerBound..<$0.upperBound]
//        }
//        return fileName.flatMap(String.init)
//    }
    
    private func decodeMessageId(_ json: JsonElement) -> ProtoEventBundle? {
        guard let data = json["data"].string,
              let privateId = json["context"].string,
              let (messageId, messageDate) = splitIntoParts(messageIdWithTS: data)
        else {
            return nil
        }
        
        return ProtoEventBundle(
            type: .chat(.message),
            id: privateId,
            subject: SdkChatProtoMessageSubject.delivered(
                messageWithId: messageId,
                andPrivateId: privateId,
                at: messageDate
            )
        )
    }
    
    private func decodeMessageAck(_ json: JsonElement) -> ProtoEventBundle? {
        guard let data = json["data"].string,
              let (messageId, messageDate) = splitIntoParts(messageIdWithTS: data)
        else {
            return nil
        }
        
        return ProtoEventBundle(
            type: .chat(.message),
            id: messageId,
            subject: SdkChatProtoMessageSubject.seen(
                messageWithId: messageId,
                andDate: messageDate
            )
        )
    }
    
    private func decodeChatRate(_ json: JsonElement) -> ProtoEventBundle? {
        return ProtoEventBundle(
            type: .chat(.message),
            id: json["id"].stringValue,
            subject: SdkChatProtoMessageSubject.rate
        )
    }
    
    private func decodeMessageTextPlain(_ json: JsonElement) -> ProtoEventBundle? {
        guard let id = json["id"].string,
              let data = json["data"].string,
              let userId = json["from"].string,
              let (messageId, messageDate) = splitIntoParts(messageIdWithTS: id)
        else {
            return nil
        }
        
        return ProtoEventBundle(
            type: .chat(.message),
            id: messageId,
            subject: SdkChatProtoMessageSubject.received(
                messageWithId: messageId,
                data: data,
                fromUserWithId: userId,
                sentAt: messageDate
            )
        )
    }
    
    private func decodeMessageAsMediaLink(_ json: JsonElement, type: String) -> ProtoEventBundle? {
        guard let id = json["id"].string,
              let userId = json["from"].string,
              let (messageId, messageDate) = splitIntoParts(messageIdWithTS: id)
        else {
            return nil
        }
        
        let mimeType = SdkChatProtoMessageMediaMimeType(string: type)
        let mediaType = mimeType.flatMap(JVMessageMediaType.init(mimeType:))
        let mediaName = json["data"].string
            .flatMap(URL.init(string:))?
            .lastPathComponent
            ?? "unnamed_media_file"
        
        return ProtoEventBundle(
            type: .chat(.message),
            id: id,
            subject: SdkChatProtoMessageSubject.received(
                messageWithId: messageId,
                data: nil,
                andMedia: SdkChatProtoAtomMessageMedia(
                    name: mediaName,
                    mime: type,
                    type: mediaType ?? .unknown,
                    link: json["data"].stringValue
                ),
                fromUserWithId: userId,
                sentAt: messageDate
            )
        )
    }
    
    private func decodeMessageAsMediaMarkdown(_ json: JsonElement, type: String) -> ProtoEventBundle? {
        guard let id = json["id"].string,
              let userId = json["from"].string,
              let (messageId, messageDate) = splitIntoParts(messageIdWithTS: id)
        else {
            return nil
        }
        
        do {
            let markdown = json["data"].stringValue
            
            let regex = try NSRegularExpression(pattern: "^!\\[[^\\]]*\\]\\((.*?)\\)$")
            guard let match = regex.firstMatch(in: markdown, range: NSRange(location: 0, length: markdown.utf16.count))
            else {
                return nil
            }
            
            let link = (markdown as NSString).substring(with: match.range(at: 1))
            let mimeType = SwiftMime.mime((link as NSString).pathExtension).flatMap(SdkChatProtoMessageMediaMimeType.init)
            let mediaType = mimeType.flatMap(JVMessageMediaType.init(mimeType:))
            let mediaName = URL(string: link)?
                .lastPathComponent
                ?? "unnamed_media_file"
            
            return ProtoEventBundle(
                type: .chat(.message),
                id: id,
                subject: SdkChatProtoMessageSubject.received(
                    messageWithId: messageId,
                    data: nil,
                    andMedia: SdkChatProtoAtomMessageMedia(
                        name: mediaName,
                        mime: type,
                        type: mediaType ?? .unknown,
                        link: link
                    ),
                    fromUserWithId: userId,
                    sentAt: messageDate
                )
            )
        }
        catch {
            return nil
        }
    }
    
    private func decodeUser(_ json: JsonElement) -> ProtoEventBundle? {
        guard let status = json["data"].string
        else {
            return nil
        }
        
        if let id = json["id"].string {
            return ProtoEventBundle(
                type: .chat(.user),
                id: id,
                subject: SdkChatProtoUserSubject.statusUpdated(
                    to: status,
                    ofUserWithId: id
                )
            )
        }
        else {
            return ProtoEventBundle(
                type: .chat(.user),
                id: nil,
                subject: SdkChatProtoUserSubject.switchingDataReceivingMode
            )
        }
    }
    
    private func decodeUserName(_ json: JsonElement) -> ProtoEventBundle? {
        guard let id = json["id"].string,
              let name = json["data"].string
        else {
            return nil
        }
        
        return ProtoEventBundle(
            type: .chat(.user),
            id: id,
            subject: SdkChatProtoUserSubject.nameUpdated(
                to: name,
                ofUserWithId: id
            )
        )
    }
    
    private func decodeUserTitle(_ json: JsonElement) -> ProtoEventBundle? {
        guard let id = json["id"].string,
              let title = json["data"].string
        else {
            return nil
        }
        
        return ProtoEventBundle(
            type: .chat(.user),
            id: id,
            subject: SdkChatProtoUserSubject.titleUpdated(
                to: title,
                ofUserWithId: id
            )
        )
    }
    
    private func decodeUserPhoto(_ json: JsonElement) -> ProtoEventBundle? {
        guard let id = json["id"].string,
              let photoUrl = json["data"].string
        else {
            return nil
        }
        
        return ProtoEventBundle(
            type: .chat(.user),
            id: id,
            subject: SdkChatProtoUserSubject.photoUpdated(
                to: photoUrl,
                ofUserWithId: id
            )
        )
    }
    
    // MARK: Other
    
    private func splitIntoParts(messageIdWithTS idWithTS: String) -> (Int, Date)? {
        let parts = idWithTS.split(separator: ".")
        
        let id = parts.first
            .flatMap(String.init)
            .flatMap(Int.init)
        
        let date = parts.last
            .flatMap(String.init)
            .flatMap(Int.init)
            .flatMap(TimeInterval.init)
            .flatMap(Date.init(timeIntervalSince1970:))
        
        if let id = id, let date = date {
            return (id: id, date: date)
        }
        else {
            return nil
        }
    }
}

extension ProtoEventSubjectPayload {
    struct RecentActivity: IProtoEventSubjectPayloadModel {
        struct Body {
            let latestMessageId: Int?
        }
        
        static let kindId = UUID()
        let status: RestResponseStatus
        let body: Body
    }
}
