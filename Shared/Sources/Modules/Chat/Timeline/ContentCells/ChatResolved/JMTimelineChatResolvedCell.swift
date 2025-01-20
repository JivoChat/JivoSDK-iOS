//
//  JMTimelineChatResolvedCell.swift
//  App
//
//  Created by Julia Popova on 28.06.2024.
//

import Foundation
import DTModelStorage
import JMTimelineKit

final class JMTimelineChatResolvedCell: JMTimelineEventCell, ModelTransfer {
    let internalCanvas = JMTimelineChatResolvedCanvas()
    
    override func obtainCanvas() -> JMTimelineCanvas {
        return internalCanvas
    }
    
    func update(with model: JMTimelineChatResolvedItem) {
        container.configure(item: model)
        
        internalCanvas.closeHandler = { [weak self] in
            guard self != nil else { return }
            model.payload.interactor.resolveCurrentChat()
        }
    }
}
