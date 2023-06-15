//
//  JMTimelineMessagePlainItem.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import JMTimelineKit

struct JMTimelineMessagePlainInfo: JMTimelineInfo {
    let text: String
    let style: JMTimelineCompositePlainStyle
    
    init(text: String, style: JMTimelineCompositePlainStyle) {
        self.text = text
        self.style = style
    }
}

typealias JMTimelinePlainStyle = JMTimelineCompositePlainStyle

final class JMTimelineMessagePlainItem: JMTimelineMessageItem {
}
