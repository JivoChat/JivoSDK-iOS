//
//  JMTimelineMessageEmojiItem.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMTimelineKit

struct JMTimelineMessageEmojiInfo: JMTimelineInfo {
    let emoji: String
    let style: JMTimelineCompositePlainStyle
    
    init(emoji: String, style: JMTimelineCompositePlainStyle) {
        self.emoji = emoji
        self.style = style
    }
}

typealias JMTimelineEmojiStyle = JMTimelineCompositeRichStyle

final class JMTimelineMessageEmojiItem: JMTimelineMessageItem {
}
