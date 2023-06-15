//
//  ChatCacheService.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 03/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

fileprivate let kTypingActiveTimeout = TimeInterval(5)

protocol IChatCacheService: AnyObject {
    func earliestMessage(for chat: JVChat) -> ChatCacheEarliestMeta?
    func earliestMessageValid(for chat: JVChat) -> Bool
    func cache(earliestMessage message: JVMessage, for chat: JVChat)
    func resetEarliestMessage(for chat: JVChat)

    var typingObservable: JVBroadcastTool<ChatCacheTypingMeta> { get }
    func startTyping(chat: JVChat, human: JVDisplayable, text: String?)
    func stopTyping(chat: JVChat, human: JVDisplayable)
    func obtainTyping(chat: JVChat) -> (humans: [JVDisplayable], input: String)?
}

struct ChatCachingKey: Hashable {
    enum RequestingMode {
        case perClient
        case perChat
    }
    
    let requestingMode: RequestingMode
    let ID: Int
}

final class ChatCacheTypingMeta {
    var humans = [(human: JVDisplayable, date: Date)]()
    var text: String?
    let actualInterval = kTypingActiveTimeout
    
    var isValid: Bool {
        return humans.allSatisfy { $0.human.jv_isValid }
    }

    func addHuman(_ human: JVDisplayable) {
        if let index = indexOf(human: human) {
            humans[index] = (human, Date())
        }
        else {
            humans.append((human, Date()))
        }
    }

    @discardableResult func removeHuman(_ human: JVDisplayable) -> Bool {
        guard let index = indexOf(human: human) else { return false }
        humans.remove(at: index)
        return true
    }

    private func indexOf(human: JVDisplayable) -> Int? {
        humans = humans.filter { $0.human.jv_isValid }
        let hashes = humans.map { $0.human.hashedID }
        return hashes.firstIndex(of: human.hashedID)
    }
}

final class ChatCacheService: IChatCacheService {
    let typingObservable = JVBroadcastTool<ChatCacheTypingMeta>()

    private var earliestMetas = [ChatCachingKey: ChatCacheEarliestMeta]()
    private var typingMetas = [Int: ChatCacheTypingMeta]()
    
    init() {
    }

    func earliestMessage(for chat: JVChat) -> ChatCacheEarliestMeta? {
        guard let key = cachingKey(chat: chat) else {
            return nil
        }
        
        if let data = earliestMetas[key], data.chatID == chat.ID {
            return data.message.jv_isValid ? data : nil
        }
        else if let message = chat.lastMessage, message.jv_isValid {
            cache(earliestMessage: message, for: chat)
            return earliestMetas[key]
        }
        else {
            return nil
        }
    }
    
    func earliestMessageValid(for chat: JVChat) -> Bool {
        guard let key = cachingKey(chat: chat) else {
            return false
        }

        if let data = earliestMetas[key], data.chatID == chat.ID {
            return data.message.jv_isValid
        }
        else {
            return false
        }
    }
    
    func cache(earliestMessage message: JVMessage, for chat: JVChat) {
        guard let key = cachingKey(chat: chat) else { return }
        guard message.jv_isValid else { return }
        
        let data = earliestMetas[key]
        let sameChatID = (chat.ID == data?.chatID)
        
        if let lastMessage = data?.message, lastMessage.jv_isValid, sameChatID, message.ID > lastMessage.ID {
            return
        }
        else {
            earliestMetas[key] = ChatCacheEarliestMeta(chatID: chat.ID, message: message)
        }
    }
    
    func resetEarliestMessage(for chat: JVChat) {
        guard let key = cachingKey(chat: chat) else {
            return
        }

        earliestMetas.removeValue(forKey: key)
    }

    func startTyping(chat: JVChat, human: JVDisplayable, text: String?) {
        func _adjust(meta: ChatCacheTypingMeta) {
            meta.addHuman(human)
            meta.text = text ?? meta.text
        }

        if let meta = typingMetas[chat.ID] {
            _adjust(meta: meta)
            typingObservable.broadcast(meta, async: .main)
        }
        else {
            let meta = ChatCacheTypingMeta()
            typingMetas[chat.ID] = meta

            _adjust(meta: meta)
            typingObservable.broadcast(meta, async: .main)
        }
    }

    func stopTyping(chat: JVChat, human: JVDisplayable) {
        guard let meta = typingMetas[chat.ID] else { return }
        meta.removeHuman(human)

        DispatchQueue.main.jv_delayed(seconds: 0.25) { [weak self] in
            guard meta.isValid else { return }
            self?.typingObservable.broadcast(meta)
        }
    }

    func obtainTyping(chat: JVChat) -> (humans: [JVDisplayable], input: String)? {
        guard let meta = typingMetas[chat.ID] else { return nil }
        guard let input = meta.text else { return nil }
        guard !meta.humans.isEmpty else { return nil }

        meta.humans = meta.humans.filter { $0.human.jv_isValid }
        let actualHumans: [JVDisplayable] = meta.humans.compactMap { human in
            guard human.date > Date().addingTimeInterval(-kTypingActiveTimeout) else { return nil }
            return human.human
        }

        if actualHumans.isEmpty {
            return nil
        }
        else {
            return (humans: actualHumans, input: input)
        }
    }
    
    private func cachingKey(chat: JVChat) -> ChatCachingKey? {
        guard let chat = jv_validate(chat) else {
            return nil
        }
        
        if let client = chat.client {
            return ChatCachingKey(requestingMode: .perClient, ID: client.ID)
        }
        else {
            return ChatCachingKey(requestingMode: .perChat, ID: chat.ID)
        }
    }
}
