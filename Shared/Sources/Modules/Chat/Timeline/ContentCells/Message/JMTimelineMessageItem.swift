//
// Created by Stan Potemkin on 09/08/2018.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMRepicKit
import JMTimelineKit

enum JMTimelineItemDelivery {
    case hidden
    case queued
    case sent
    case delivered
    case seen
    case failed
}

enum JMTimelineItemPosition {
    case left
    case right
}

struct JMTimelineItemSender {
    let ID: String
    let icon: JMRepicItem?
    let name: String?
    let mark: String?
    let style: JMTimelineMessageSenderStyle
    
    init(
        ID: String,
        icon: JMRepicItem?,
        name: String?,
        mark: String?,
        style: JMTimelineMessageSenderStyle
    ) {
        self.ID = ID
        self.icon = icon
        self.name = name
        self.mark = mark
        self.style = style
    }
}

struct JMTimelineRenderOptions: OptionSet {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    static let useEntireCanvas = JMTimelineRenderOptions(rawValue: 1 << 0)
    static let showStatusBar = JMTimelineRenderOptions(rawValue: 1 << 1)
    static let showQuoteLine = JMTimelineRenderOptions(rawValue: 1 << 2)
}

struct JMTimelineMessagePayload {
    let kindID: String
    let sender: JMTimelineItemSender
    let footer: ChatTimelineMessageExtras
    let renderOptions: JMTimelineMessageRenderOptions
    let provider: JVChatTimelineProvider
    let interactor: JVChatTimelineInteractor
    let regionsGenerator: () -> [JMTimelineMessageCanvasRegion]
    let regionsPopulator: ([JMTimelineMessageCanvasRegion]) -> Void
}

class JMTimelineMessageItem: JMTimelinePayloadItem<JMTimelineMessagePayload> {
    override var groupingID: String? {
        return payload.sender.ID
    }
}

struct JMTimelineMessageItemSub {
    let position: JMTimelineItemPosition
    let renderOptions: JMTimelineRenderOptions
    let delivery: JMTimelineItemDelivery
    let status: String?
    
    init(
        position: JMTimelineItemPosition,
        renderOptions: JMTimelineRenderOptions,
        delivery: JMTimelineItemDelivery,
        status: String?
    ) {
        self.position = position
        self.renderOptions = renderOptions
        self.delivery = delivery
        self.status = status
    }
}
