//
// Created by Stan Potemkin on 09/08/2018.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMTimelineKit

struct JMTimelineRichStyle: JMTimelineStyle {
    init() {
    }
}

struct JMTimelineMessageRichInfo: JMTimelineInfo {
    let content: NSAttributedString
    
    init(content: NSAttributedString) {
        self.content = content
    }
}

final class JMTimelineMessageRichItem: JMTimelineMessageItem {
}
