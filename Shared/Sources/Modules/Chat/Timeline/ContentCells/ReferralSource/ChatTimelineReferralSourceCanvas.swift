//
//  ChatTimelineReferralSourceCanvas.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 31.10.2024.
//

import Foundation
import UIKit
import JMTimelineKit

class ChatTimelineReferralSourceCanvas: JMTimelineSingleCanvas<ChatTimelineReferralSourceRegion> {
    init() {
        super.init(region: ChatTimelineReferralSourceRegion())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure(item: JMTimelineItem) {
        super.configure(item: item)
    }
}
