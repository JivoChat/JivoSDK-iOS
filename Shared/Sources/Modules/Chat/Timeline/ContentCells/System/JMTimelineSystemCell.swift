//
//  JMTimelineSystemCell.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import DTModelStorage
import JMRepicKit
import JMTimelineKit

final class JMTimelineSystemCell: JMTimelineEventCell, ModelTransfer {
    let internalCanvas = JMTimelineSystemCanvas()
    
    override func obtainCanvas() -> JMTimelineCanvas {
        return internalCanvas
    }
    
    func update(with model: JMTimelineSystemItem) {
        container.configure(item: model)
    }
}
