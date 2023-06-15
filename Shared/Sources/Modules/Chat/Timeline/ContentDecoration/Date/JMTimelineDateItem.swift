//
//  JMTimelineDateItem.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 19/08/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import JMTimelineKit

struct JMTimelineDateInfo: JMTimelineInfo {
    let caption: String
    
    init(caption: String) {
        self.caption = caption
    }
}

final class JMTimelineDateItem: JMTimelinePayloadItem<JMTimelineDateInfo> {
}
