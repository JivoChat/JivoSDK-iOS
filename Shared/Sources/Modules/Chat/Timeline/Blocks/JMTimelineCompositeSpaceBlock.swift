//
//  JMTimelineCompositeSpaceBlock.swift
//  JMTimeline
//
//  Created by Stan Potemkin on 06.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import TypedTextAttributes
import JMMarkdownKit
import JMTimelineKit

struct JMTimelineCompositeSpaceStyle: JMTimelineStyle {
    let height: CGFloat

    init(height: CGFloat) {
        self.height = height
    }
}

final class JMTimelineCompositeSpaceBlock: UIView, JMTimelineBlockCallable {
    init() {
        super.init(frame: .zero)
        
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func link(provider: JMTimelineProvider, interactor: JMTimelineInteractor) {
    }
    
    func updateDesign() {
    }
    
    func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return true
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size))
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    
    var totalSize: CGSize {
        return CGSize(width: bounds.width, height: 10)
    }
}
