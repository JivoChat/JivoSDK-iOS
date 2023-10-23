//
//  JMTimelineMessagePlainItem.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import JMTimelineKit

struct JMTimelineMessagePlainInfo: JMTimelineInfo {
    let quotedMessage: JVMessage?
    let text: String
    let style: JMTimelineCompositePlainStyle
}

typealias JMTimelinePlainStyle = JMTimelineCompositePlainStyle

final class JMTimelineMessagePlainItem: JMTimelineMessageItem {
}
