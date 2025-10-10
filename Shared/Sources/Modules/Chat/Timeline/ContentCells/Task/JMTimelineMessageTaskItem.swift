//
//  JMTimelineMessageTaskItem.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMRepicKit
import JMTimelineKit

struct JMTimelineMessageTaskInfo: JMTimelineInfo {
    let icon: UIImage?
    let brief: String
    let agentRepic: JMRepicItem?
    let agentName: String
    let date: String

    init(
        icon: UIImage?,
        brief: String,
        agentRepic: JMRepicItem?,
        agentName: String,
        date: String
    ) {
        self.icon = icon
        self.brief = brief
        self.agentRepic = agentRepic
        self.agentName = agentName
        self.date = date
    }
}

struct JMTimelineTaskStyle: JMTimelineStyle {
    let briefLabelColor: UIColor
    let briefLabelFont: UIFont
    let agentNameColor: UIColor
    let agentNameFont: UIFont
    let dateColor: UIColor
    let dateFont: UIFont
    
    init(briefLabelColor: UIColor,
                briefLabelFont: UIFont,
                agentNameColor: UIColor,
                agentNameFont: UIFont,
                dateColor: UIColor,
                dateFont: UIFont) {
        self.briefLabelColor = briefLabelColor
        self.briefLabelFont = briefLabelFont
        self.agentNameColor = agentNameColor
        self.agentNameFont = agentNameFont
        self.dateColor = dateColor
        self.dateFont = dateFont
    }
}

final class JMTimelineMessageTaskItem: JMTimelineMessageItem {
}
