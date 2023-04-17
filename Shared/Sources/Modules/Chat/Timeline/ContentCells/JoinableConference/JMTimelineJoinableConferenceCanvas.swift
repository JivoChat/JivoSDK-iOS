//
//  JMTimelineJoinableConferenceCanvas.swift
//  JMTimelineKit
//
//  Created by Stan Potemkin on 16.12.2021.
//

import Foundation
import UIKit
import JMTimelineKit

class JMTimelineJoinableConferenceCanvas: JMTimelineSingleCanvas<JMTimelineMessageJoinableConferenceRegion> {
    init() {
        super.init(region: JMTimelineMessageJoinableConferenceRegion())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure(item: JMTimelineItem) {
        super.configure(item: item)
    }
}

