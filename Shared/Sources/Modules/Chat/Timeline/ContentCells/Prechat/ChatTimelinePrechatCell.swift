//
//  ChatTimelinePrechatCell.swift
//  Pods
//
//  Created by Stan Potemkin on 07.11.2024.
//

import Foundation
import DTModelStorage
import JMTimelineKit

final class ChatTimelinePrechatCell: JMTimelineEventCell, ModelTransfer {
    let internalCanvas = ChatTimelinePrechatCanvas()
    
    override func obtainCanvas() -> JMTimelineCanvas {
        return internalCanvas
    }
    
    func update(with model: ChatTimelinePrechatItem) {
        container.configure(item: model)
    }
}
