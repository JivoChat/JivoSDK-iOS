//
//  JMTimelineTaskCell.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import DTModelStorage
import JMTimelineKit

final class JMTimelineTaskCell: JMTimelineEventCell, ModelTransfer {
    private let internalCanvas = JMTimelineTaskCanvas()
    
    override func obtainCanvas() -> JMTimelineCanvas {
        return internalCanvas
    }
    
    func update(with model: JMTimelineTaskItem) {
        container.configure(item: model)
        
        internalCanvas.completeHandler = { [weak self] in
            guard self != nil else { return }
            
            let taskID = model.payload.taskID
            let clientID = model.payload.clientID
            let taskName = model.payload.taskName
            
            model.payload.interactor.completeTask(
                taskID: taskID,
                clientID: clientID,
                taskName: taskName
            )
        }
        
        internalCanvas.editHandler = { [weak self] in
            guard self != nil else { return }
            model.payload.interactor.openTaskEditor(taskInfo: model.payload)
        }
    }
}
