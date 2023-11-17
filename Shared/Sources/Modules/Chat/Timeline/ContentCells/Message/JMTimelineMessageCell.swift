//
//  JMTimelineMessageCell.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import DTModelStorage
import JMTimelineKit

final class JMTimelineMessageCell: JMTimelineEventCell, ModelTransfer {
    private let internalCanvas = JMTimelineMessageCanvas()
    
    override func obtainCanvas() -> JMTimelineCanvas {
        return internalCanvas
    }
    
    func update(with model: JMTimelineMessageItem) {
        container.configure(item: model)
    }
    
    func animateContentGlow(delay: Double) {
        viewWithTag(JMTimelineMessageCanvasRegionViewTag)?.jv_animateGlow(delay: delay)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        jv_discardGlow()
    }
}
