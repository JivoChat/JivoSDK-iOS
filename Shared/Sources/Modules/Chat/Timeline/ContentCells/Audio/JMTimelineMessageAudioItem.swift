//
//  JMTimelineAudioItem.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMTimelineKit

extension Notification.Name {
    static let JMAudioPlayerState = Notification.Name("JMAudioPlayerState")
}

struct JMTimelineMessageAudioInfo: JMTimelineInfo {
    let URL: URL
    let title: String?
    let duration: TimeInterval?
    let style: JMTimelineCompositeAudioStyleExtended
    
    init(URL: URL,
                title: String?,
                duration: TimeInterval?,
                style: JMTimelineCompositeAudioStyleExtended) {
        self.URL = URL
        self.title = title
        self.duration = duration
        self.style = style
    }
}

typealias JMTimelineAudioStyle = JMTimelineCompositeAudioStyle

final class JMTimelineMessageAudioItem: JMTimelineMessageItem {
}
