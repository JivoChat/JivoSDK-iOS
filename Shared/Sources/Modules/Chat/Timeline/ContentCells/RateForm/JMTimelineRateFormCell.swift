//
//  JMTimelineRateFormCell.swift
//  JivoSDK
//
//  Created by Julia Popova on 27.09.2023.
//

import UIKit
import DTModelStorage
import JMRepicKit
import JMTimelineKit

final class JMTimelineRateFormCell: JMTimelineEventCell, ModelTransfer {
    let internalCanvas = JMTimelineRateFormCanvas()
    
    override func obtainCanvas() -> JMTimelineCanvas {
        return internalCanvas
    }
    
    func update(with model: JMTimelineRateFormItem) {
        container.configure(item: model)
    }
}
