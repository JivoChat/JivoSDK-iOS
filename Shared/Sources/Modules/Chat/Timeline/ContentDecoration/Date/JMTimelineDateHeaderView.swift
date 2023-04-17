//
//  JMTimelineDateHeaderView.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import DTModelStorage
import JMTimelineKit

final class JMTimelineDateHeaderView: JMTimelineHeaderView, ModelTransfer {
    private let internalCanvas = JMTimelineDateHeaderCanvas()
    
    override func obtainCanvas() -> JMTimelineCanvas {
        return internalCanvas
    }
    
    func update(with model: JMTimelineDateItem) {
        container.configure(item: model)
    }
}
