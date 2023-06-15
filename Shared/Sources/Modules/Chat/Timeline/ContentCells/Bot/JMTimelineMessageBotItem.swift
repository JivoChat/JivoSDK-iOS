//
//  JMTimelineMessageBotItem.swift
//  JMTimeline
//
//  Created by Stan Potemkin on 06.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMTimelineKit

struct JMTimelineMessageBotInfo: JMTimelineInfo {
    let text: String
    let style: JMTimelineCompositePlainStyle
    let buttons: [String]
    let tappable: Bool

    init(text: String, style: JMTimelineCompositePlainStyle, buttons: [String], tappable: Bool) {
        self.text = text
        self.style = style
        self.buttons = buttons
        self.tappable = tappable
    }
}

struct JMTimelineMessageButtonsInfo: JMTimelineInfo {
    let buttons: [String]
    let tappable: Bool

    init(buttons: [String], tappable: Bool) {
        self.buttons = buttons
        self.tappable = tappable
    }
}
