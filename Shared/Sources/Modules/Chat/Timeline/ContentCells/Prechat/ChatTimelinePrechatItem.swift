//
//  ChatTimelinePrechatItem.swift
//  Pods
//
//  Created by Stan Potemkin on 07.11.2024.
//

import JMTimelineKit

struct ChatTimelinePrechatInfo: JMTimelineInfo {
    let captions: [String]
    let provider: JVChatTimelineProvider
    let interactor: JVChatTimelineInteractor
}

final class ChatTimelinePrechatItem: JMTimelinePayloadItem<ChatTimelinePrechatInfo> {
}
