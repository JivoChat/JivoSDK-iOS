//
//  JMTimelineCompositeRichBlock.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import TypedTextAttributes
import JMTimelineKit

struct JMTimelineCompositeRichStyle: JMTimelineStyle {
    init() {
    }
}

final class JMTimelineCompositeRichBlock: UILabel, JMTimelineBlockCallable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        numberOfLines = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func link(provider: JMTimelineProvider, interactor: JMTimelineInteractor) {
    }
    
    func configure(rich: NSAttributedString) {
        attributedText = rich
    }
    
    func updateDesign() {
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if (attributedText?.string).jv_orEmpty.isEmpty {
            return .zero
        } 
        else {
            return super.sizeThatFits(size)
        }
    }

    func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return false
    }
}
