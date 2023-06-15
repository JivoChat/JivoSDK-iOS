//
//  JMTimelineMessageCallItem.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 27/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMRepicKit
import JMTimelineKit

struct JMTimelineMessageCallInfo: JMTimelineInfo {
    let repic: JMRepicItem?
    let state: String
    let phone: String?
    let recordURL: URL?
    let duration: TimeInterval?
    
    init(repic: JMRepicItem?,
                state: String,
                phone: String?,
                recordURL: URL?,
                duration: TimeInterval?) {
        self.repic = repic
        self.state = state
        self.phone = phone
        self.recordURL = recordURL
        self.duration = duration
    }
}

struct JMTimelineCallStyle: JMTimelineStyle {
    let stateColor: UIColor
    let stateFont: UIFont
    let playControlBorderColor: UIColor
    let playControlTintColor: UIColor
    let playControlSide: CGFloat
    let playControlCategory: UIFont.TextStyle
    let sliderThumbSide: CGFloat
    let sliderThumbColor: UIColor
    let sliderMinColor: UIColor
    let sliderMaxColor: UIColor
    let phoneColor: UIColor
    let phoneFont: UIFont
    let phoneLinesLimit: Int
    let durationColor: UIColor
    let durationFont: UIFont

    init(stateColor: UIColor,
                stateFont: UIFont,
                playControlBorderColor: UIColor,
                playControlTintColor: UIColor,
                playControlSide: CGFloat,
                playControlCategory: UIFont.TextStyle,
                sliderThumbSide: CGFloat,
                sliderThumbColor: UIColor,
                sliderMinColor: UIColor,
                sliderMaxColor: UIColor,
                phoneColor: UIColor,
                phoneFont: UIFont,
                phoneLinesLimit: Int,
                durationColor: UIColor,
                durationFont: UIFont) {
        self.stateColor = stateColor
        self.stateFont = stateFont
        self.playControlBorderColor = playControlBorderColor
        self.playControlTintColor = playControlTintColor
        self.playControlSide = playControlSide
        self.playControlCategory = playControlCategory
        self.sliderThumbSide = sliderThumbSide
        self.sliderThumbColor = sliderThumbColor
        self.sliderMinColor = sliderMinColor
        self.sliderMaxColor = sliderMaxColor
        self.phoneColor = phoneColor
        self.phoneFont = phoneFont
        self.phoneLinesLimit = phoneLinesLimit
        self.durationColor = durationColor
        self.durationFont = durationFont
    }
}

class JMTimelineMessageCallItem: JMTimelineMessageItem {
}
