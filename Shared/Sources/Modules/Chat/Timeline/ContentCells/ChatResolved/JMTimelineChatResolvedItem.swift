//
//  JMTimelineChatResolvedItem.swift
//  App
//
//  Created by Julia Popova on 28.06.2024.
//

import Foundation
import JMTimelineKit

struct JMTimelineChatResolvedInfo: JMTimelineInfo {
    let keyboardAnchorControl: KeyboardAnchorControl
    let provider: JVChatTimelineProvider
    let interactor: JVChatTimelineInteractor
}

final class JMTimelineChatResolvedItem: JMTimelinePayloadItem<JMTimelineChatResolvedInfo> { }

