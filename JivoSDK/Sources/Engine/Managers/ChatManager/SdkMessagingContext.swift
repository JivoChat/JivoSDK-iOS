//
//  SdkMessagingContext.swift
//  Demo
//
//  Created by Stan Potemkin on 01.02.2023.
//

import Foundation


protocol ISdkMessagingContext: AnyObject {
    var eventObservable: JVBroadcastTool<SdkMessagingEvent> { get }
    func broadcast(event: SdkMessagingEvent)
    func broadcast(event: SdkMessagingEvent, onQueue queue: DispatchQueue)
}

enum SdkMessagingEvent {
    case messagesUpserted(_ messages: [DatabaseEntityRef<MessageEntity>])
    case messagesRemoved(_ messages: [DatabaseEntityRef<MessageEntity>])
    case messageSending(_ message: DatabaseEntityRef<MessageEntity>)
    case messageResend(_ message: DatabaseEntityRef<MessageEntity>)
    case historyLoaded(history: [DatabaseEntityRef<MessageEntity>])
    case allHistoryLoaded
    case historyErased
}

final class SdkMessagingContext: ISdkMessagingContext {
    let eventObservable = JVBroadcastTool<SdkMessagingEvent>()
    
    private var unreadNumber = 0
    
    func broadcast(event: SdkMessagingEvent) {
        eventObservable.broadcast(event)
    }
    
    func broadcast(event: SdkMessagingEvent, onQueue queue: DispatchQueue) {
        eventObservable.broadcast(event, async: queue)
    }
}
