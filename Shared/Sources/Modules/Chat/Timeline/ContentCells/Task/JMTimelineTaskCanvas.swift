//
//  JMTimelineTaskCanvas.swift
//  JMTimelineKit
//
//  Created by Stan Potemkin on 16.12.2021.
//

import Foundation
import UIKit
import JMTimelineKit

class JMTimelineTaskCanvas: JMTimelineSingleCanvas<JMTimelineMessageTaskRegion> {
    init() {
        super.init(region: JMTimelineMessageTaskRegion())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure(item: JMTimelineItem) {
        super.configure(item: item)
    }
}

