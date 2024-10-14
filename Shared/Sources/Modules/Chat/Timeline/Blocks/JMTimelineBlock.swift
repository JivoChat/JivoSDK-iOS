//
//  JMTimelineBlock.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMTimelineKit

extension JMTimelineBlock {
    static let defaultCornerRadius = 14.0
}

class JMTimelineBlock: UIView, JMTimelineBlockCallable {
    private(set) weak var provider: JVChatTimelineProvider?
    private(set) weak var interactor: JVChatTimelineInteractor?
    
    init() {
        super.init(frame: .zero)
        updateDesign()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func linkTo(provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        self.provider = provider
        self.interactor = interactor
    }
    
    func updateDesign() {
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDesign()
    }
    
    func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return false
    }
}
