//
//  ChatHistory.swift
//  JMTimeline
//
//  Created by Stan Potemkin on 30/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

import DTCollectionViewManager
import DTModelStorage
import JMTimelineKit

fileprivate class JMTimelineHistoryContext {
    var recentItemsMap = [Int: Any]()
    var shouldResetCache: Bool
    
    init(shouldResetCache: Bool) {
        self.shouldResetCache = shouldResetCache
    }
}

struct ChatHistoryConfig: JMTimelineHistoryConfig {
    typealias GroupingFront = FrontItem
    enum FrontItem: Int, CaseIterable {
        case bottom = 0
        case prechat = 1
        case typing = 2
    }
    
    typealias GroupingBack = BackItem
    enum BackItem: Int, CaseIterable {
        case top = 0
    }
}

final class ChatHistory {
    var messages: [MessageEntity] = [] // First elements is the earliest messages, last elements is the latest messages
    
    var updateHistoryHandler: ((Bool) -> Void)?
    var needScrollHandler: (() -> Void)?
    
    private let timelineHistory: JMTimelineHistory<ChatHistoryConfig>
    private let databaseDriver: JVIDatabaseDriver
    private let factory: ChatTimelineFactory
    private let collectionViewManager: DTCollectionViewManager
    private let chatRef: DatabaseEntityRef<ChatEntity>?
    private let chatCacheService: IChatCacheService
    private let workerThread: JVIDispatchThread
    
    private var currentBottomItem: JMTimelineItem?
    private var itemsCounter = 0
    private var cachedUnreadPosition: ChatEntity.UnreadMarkPosition
    private var recentTimepointItem: JMTimelineItem?
    private var uncachableUUIDs = Set<String>()
    private var recentUid: String?
//    private var momentaryUid: String?

    private var isTyping = false
    
    init(
        timelineHistory: JMTimelineHistory<ChatHistoryConfig>,
        databaseDriver: JVIDatabaseDriver,
        factory: ChatTimelineFactory,
        collectionViewManager: DTCollectionViewManager,
        chat: ChatEntity?,
        chatCacheService: IChatCacheService,
        timelineCache: JMTimelineCache,
        workerThread: JVIDispatchThread
    ) {
        self.timelineHistory = timelineHistory
        self.databaseDriver = databaseDriver
        self.factory = factory
        self.collectionViewManager = collectionViewManager
        self.chatCacheService = chatCacheService
        self.workerThread = workerThread
        
        chatRef = databaseDriver.reference(to: chat)
        cachedUnreadPosition = chat?.unreadMarkPosition ?? .null
    }
    
    var cache: JMTimelineCache {
        return timelineHistory.cache
    }
    
    func prepare() {
        timelineHistory.prepare()
        informHistoryHandler()
    }
    
    func setTopItem(_ item: JMTimelineItem?) {
        if timelineHistory.placeStandalone(item: item, target: .top, animated: false) {
            informHistoryHandler()
        }
    }
    
    func setTyping(sender: JVDisplayable?, text: String?) {
        let item: JMTimelineItem?
        if let text {
            item = factory.generateTypingItem(sender: sender, text: text)
        }
        else {
            item = nil
        }
        
        if timelineHistory.placeStandalone(item: item, target: .typing, animated: true) {
            informHistoryHandler()
        }
    }
    
    func setBottomItem(_ item: JMTimelineItem?) {
        guard item != currentBottomItem else { return }
        currentBottomItem = item
        
        if timelineHistory.placeStandalone(item: item, target: .bottom, animated: false) {
            informHistoryHandler()
        }
    }
    
    func setPrechat(captions: [String]?) {
        let item: JMTimelineItem?
        if let captions, captions.jv_hasElements {
            item = factory.generatePrechatButtons(captions: captions)
        }
        else {
            item = nil
        }
        
        if timelineHistory.placeStandalone(item: item, target: .prechat, animated: false) {
            informHistoryHandler()
        }
    }
    
    func fill(with messages: [MessageEntity], partialLoaded: Bool, unreadPosition: ChatEntity.UnreadMarkPosition) {
        collectionViewManager.memoryStorage.performUpdates { [weak self] in
            let messages = messages.filter { !$0.isHidden }
            
            self?.messages = messages
            self?.messages.sort { $0.date < $1.date }

            if let chat = self?.chatRef?.resolve() {
                self?.chatCacheService.resetEarliestMessage(for: chat)
            }
            
            self?.itemsCounter = messages.count
            self?.feedItems(forMessages: messages, unreadPosition: unreadPosition, partialLoaded: partialLoaded) { items in
                self?.uncachableUUIDs = Set(items.filter(\.uncachable).map(\.uid))
                self?.timelineHistory.fill(with: items)
            }

            if let chat = self?.chatRef?.resolve(), let oldestMessage = messages.last {
                self?.chatCacheService.cache(earliestMessage: oldestMessage, for: chat)
            }

            self?.informHistoryHandler(!messages.isEmpty)
        }
        collectionViewManager.collectionViewUpdater?.storageNeedsReloading()
    }
    
    func populate(withMessages insertingMessages: [MessageEntity]) {
        if insertingMessages.jv_hasElements {
            self.messages.append(contentsOf: insertingMessages)
            self.messages.sort { $0.date < $1.date }
            
            let historyItems = insertingMessages.dropLast(1).map { factory.generateItem(for: $0, position: .history) }
            let recentItems = insertingMessages.suffix(1).map { factory.generateItem(for: $0, position: .recent) }
            let items = historyItems + recentItems
            uncachableUUIDs = uncachableUUIDs.union(items.filter(\.uncachable).map(\.uid))
            
            if let recentItem = recentItems.last {
                reloadRecentUncachableItemIfNeeded()
                storeRecentUncachableItemIfNeeded(item: recentItem)
            }
            
            timelineHistory.populate(withItems: items)
        }
        
        informHistoryHandler(true)

        if let chat = chatRef?.resolve(), let earliestMessage = self.messages.first {
            chatCacheService.cache(earliestMessage: earliestMessage, for: chat)
        }
    }
    
    func append(messages: [MessageEntity]) {
        guard !messages.isEmpty
        else {
            return
        }
        
        let messages = messages.filter { !$0.isHidden }
        self.messages.append(contentsOf: messages)
        
        let historyItems = messages.dropLast(1).map { factory.generateItem(for: $0, position: .history) }
        let recentItems = messages.suffix(1).map { factory.generateItem(for: $0, position: .recent) }
        let items = historyItems + recentItems
        uncachableUUIDs = uncachableUUIDs.union(items.filter(\.uncachable).map(\.uid))
        
        reloadRecentUncachableItemIfNeeded()
        storeRecentUncachableItemIfNeeded(item: recentItems.last)
        
//        if let momentaryUid = momentaryUid, let message = messages.first(where: { $0.UUID == momentaryUid }) {
//            timelineHistory.replaceItem(byUUID: momentaryUid, with: factory.generateItem(for: message, position: .history))
//        }
//
//        if let recentItem = recentItems.first {
//            recentUid = recentItem.uid
//            momentaryUid = recentItem.logicOptions.contains(.enableSizeCaching) ? nil : recentUid
//        }
//        else {
//            recentUid = nil
//            momentaryUid = nil
//        }
        
        timelineHistory.append(items: items)
        informHistoryHandler(true)

        if let chat = chatRef?.resolve(), let earliestMessage = messages.last {
            chatCacheService.cache(earliestMessage: earliestMessage, for: chat)
        }
        
        updateUncachable()
        needScrollHandler?()
    }
    
    func append(message: MessageEntity) {
        append(messages: [message])
    }
    
    func remove(message: MessageEntity) {
        messages.removeAll { $0.UUID == message.UUID }
        
        timelineHistory.removeItem(byUUID: message.UUID)
        informHistoryHandler(true) // Need I set parameter to true???
        needScrollHandler?()
    }
    
    func prepend(messages: [MessageEntity], resetCache: Bool) {
        let messages = messages.filter { !$0.isHidden }
        
        self.messages.insert(contentsOf: Array(messages.reversed()), at: 0) // Try to not forget! To respect current chatHistory messages order prepending messages must be reversed!
        
        itemsCounter += messages.count

        feedItems(forMessages: messages, unreadPosition: cachedUnreadPosition, partialLoaded: true) { items in
            uncachableUUIDs.formUnion(items.filter(\.uncachable).map(\.uid))
            timelineHistory.prepend(items: items, resetCache: resetCache)
        }

        if let chat = chatRef?.resolve(), let oldestMessage = messages.last {
            chatCacheService.cache(earliestMessage: oldestMessage, for: chat)
        }
        
        informHistoryHandler(true)
    }
    
    func update(message: MessageEntity) {
        let item = factory.generateItem(for: message, position: (message.UUID == recentUid ? .recent : .history))
        
//        if message.UUID == recentUid, !item.logicOptions.contains(.enableSizeCaching) {
//            momentaryUid = recentUid
//        }
//        else {
//            momentaryUid = nil
//        }
        
        if message.isHidden {
            timelineHistory.removeItem(byUUID: message.UUID)
        }
        else {
            timelineHistory.replaceItem(byUUID: message.UUID, with: item)
        }
        
        if item.uncachable {
            uncachableUUIDs.insert(item.uid)
        }
        else {
            uncachableUUIDs.remove(item.uid)
        }
    }
    
    func reloadMessages(selectedBy messageSelection: @escaping (MessageEntity) -> Bool) {
        let messageReferences = messages.map { databaseDriver.reference(to: $0) }
        
        var identifiedItemsUids = Set<String>()
        for section in collectionViewManager.memoryStorage.sections {
            guard !section.isEmpty else {
                continue
            }
            
            if let sectionItems = (0 ..< section.numberOfItems).compactMap(section.item(at:)) as? [JMTimelineItem] {
                let leadingItems = sectionItems.filter { $0.hasLayoutOptions(.groupFirstElement) }
                let trailingItems = sectionItems.filter { $0.hasLayoutOptions(.groupLastElement) }
                identifiedItemsUids.formUnion((leadingItems + trailingItems).map(\.uid))
            }
        }
        
//        JVDesign.shared.update() // this call is needed to cache window.traitCollection.horizontalSizeClass value inside JVDesign shared instance before switching to background thread and read horizontalSizeClass value from this thread
        
        workerThread.async { [weak self] in
            guard let `self` = self
            else {
                return
            }
            
            let newItems = messageReferences
                .compactMap(\.resolved)
                .filter { identifiedItemsUids.contains($0.UUID) }
                .filter(messageSelection)
                .compactMap { message -> JMTimelineItem? in
                    self.factory.generateItem(for: message, position: (message.UUID == self.recentUid ? .recent : .history))
                }
            
            DispatchQueue.main.async { [weak self] in
                self?.collectionViewManager.memoryStorage.performUpdates {
                    newItems.forEach { newItem in
                        self?.timelineHistory.replaceItem(byUUID: newItem.uid, with: newItem)
                    }
                }
            }
        }
    }
    
    func reloadAllMessages() {
        reloadMessages(selectedBy: { _ in return true })
    }
    
    func removeTimepoint() {
        guard let item = recentTimepointItem else { return }
        recentTimepointItem = nil
        timelineHistory.removeItem(byUUID: item.uid)
    }
    
    func updateUncachable() {
        guard !(uncachableUUIDs.isEmpty) else { return }
        
        let messages = uncachableUUIDs.compactMap(databaseDriver.message)
        for message in messages {
            update(message: message)
        }
    }
    
    private func feedItems(forMessages messages: [MessageEntity], unreadPosition: ChatEntity.UnreadMarkPosition, partialLoaded: Bool, callback: ([JMTimelineItem]) -> Void) {
        let recentItems = messages.prefix(1).map { factory.generateItem(for: $0, position: .recent) }
        let historyItems = messages.dropFirst(1).map { factory.generateItem(for: $0, position: .history) }
        let items = recentItems + historyItems
        recentUid = recentItems.last?.uid
        
        reloadRecentUncachableItemIfNeeded()
        storeRecentUncachableItemIfNeeded(item: recentItems.last)
        
//        if let recentItem = recentItems.first {
//            recentUid = recentItem.uid
//            momentaryUid = recentItem.logicOptions.contains(.enableSizeCaching) ? nil : recentUid
//        }
//        else {
//            recentUid = nil
//            momentaryUid = nil
//        }
        
        switch unreadPosition {
        case .null:
            callback(items)
        case .position(let position) where position > 0 && position < itemsCounter:
            let cutPosition: Int = items.prefix(position).reduce(position) { sum, item in sum + (item.logicOptions.contains(.isVirtual) ? 1 : 0) }
            let newerItems = items.prefix(cutPosition - (itemsCounter - items.count))
            let olderItems = items.dropFirst(cutPosition)
            let timepointDate = olderItems.first?.date ?? newerItems.last?.date ?? Date()
            let timepointItem = generateTimepointItem(date: timepointDate)
            cache.preventCaching(for: Set([newerItems.last, olderItems.first].jv_flatten().map(\.uid)))
            callback(newerItems + [timepointItem] + olderItems)
            cachedUnreadPosition = .null
            recentTimepointItem = timepointItem
        case .position:
            callback(items)
        case .identifier(let identifier):
            let newerNumber = messages.filter({ $0.ID > identifier }).count
            let newerItems = items.prefix(newerNumber)
            if newerNumber > 0, newerNumber < items.count, partialLoaded {
                let olderItems = items.dropFirst(newerNumber)
                let timepointDate = olderItems.first?.date ?? newerItems.last?.date ?? Date()
                let timepointItem = generateTimepointItem(date: timepointDate)
                cache.preventCaching(for: Set([newerItems.last, olderItems.first].jv_flatten().map(\.uid)))
                callback(newerItems + [timepointItem] + olderItems)
                cachedUnreadPosition = .null
                recentTimepointItem = timepointItem
            }
            else {
                callback(items)
            }
        }
    }
    
    private func storeRecentUncachableItemIfNeeded(item: JMTimelineItem?) {
        if let item = item, item.uncachable {
            recentUid = item.uid
        }
        else {
            recentUid = nil
        }
    }
    
    private func reloadRecentUncachableItemIfNeeded() {
        guard let recentUid = recentUid,
              let message = self.messages.first(where: { $0.UUID == recentUid })
        else {
            return
        }
        
        let item = factory.generateItem(for: message, position: .history)
        timelineHistory.replaceItem(byUUID: recentUid, with: item)
    }
    
    private func generateTimepointItem(date: Date) -> JMTimelineItem {
        return factory.generateTimepointItem(date: date, caption: loc["JV_ChatTimeline_SystemIndicator_NewMessages", "Chat.System.NewMessages"])
    }

    private func informHistoryHandler(_ value: Bool? = nil) {
        let informingValue = value ?? ((timelineHistory.numberOfItems > 0) || timelineHistory.hasDeferredChanges)
        updateHistoryHandler?(informingValue)
    }
}

fileprivate extension JMTimelineItem {
    var uncachable: Bool {
        return !(logicOptions.contains(.enableSizeCaching))
    }
}
