//
//  JMTimelineCompositeCallStateBlock.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMRepicKit
import JMTimelineKit

struct JMTimelineCompositeHeadingStyle: JMTimelineStyle {
    let margin: CGFloat
    let gap: CGFloat
    let iconSize: CGSize
    let captionColor: UIColor
    let captionFont: UIFont
}

final class JMTimelineCompositeHeadingBlock: UIView, JMTimelineBlockCallable {
    private let repicView: JMRepicView
    private let captionLabel = UILabel()
    
    private var margin = CGFloat(0)
    private var gap = CGFloat(0)
    private var iconSize = CGSize.zero
    
    init(height: CGFloat) {
        repicView = JMRepicView.standard(height: height)
        
        super.init(frame: .zero)
        
        addSubview(repicView)
        
        captionLabel.numberOfLines = 0
        addSubview(captionLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func link(provider: JMTimelineProvider, interactor: JMTimelineInteractor) {
    }
    
    func configure(repic: JMRepicItem?, repicTint: UIColor?, state: String, style: JMTimelineCompositeHeadingStyle) {
        margin = style.margin
        gap = style.gap
        iconSize = style.iconSize
        
        repicView.configure(item: repic)
        repicView.tintColor = repicTint
        
        captionLabel.text = state
        captionLabel.textColor = style.captionColor
        captionLabel.font = style.captionFont
    }
    
    func updateDesign() {
    }
    
    func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return false
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        repicView.frame = layout.repicViewFrame
        captionLabel.frame = layout.statusLabelFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            statusLabel: captionLabel,
            margin: margin,
            iconSize: iconSize,
            gap: gap)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let statusLabel: UILabel
    let margin: CGFloat
    let iconSize: CGSize
    let gap: CGFloat
    
    var repicViewFrame: CGRect {
        let topY = middleY - iconSize.height * 0.5
        return CGRect(x: 0, y: topY, width: iconSize.width, height: iconSize.height)
    }
    
    var statusLabelFrame: CGRect {
        let leftX = iconSize.width + gap
        let height = statusLabelHeight
        let topY = middleY - statusLabelHeight * 0.5
        let width = bounds.width - leftX
        return CGRect(x: leftX, y: topY, width: width, height: height)
    }
    
    var totalSize: CGSize {
        let width = bounds.width
        let height = max(iconSize.height, statusLabelFrame.height) + margin * 2
        return CGSize(width: width, height: height)
    }
    
    private var middleY: CGFloat {
        return margin + max(repicViewHeight, statusLabelHeight) * 0.5
    }
    
    private var repicViewHeight: CGFloat {
        return iconSize.height
    }
    
    private var statusLabelHeight: CGFloat {
        let leftX = iconSize.width + gap
        let width = bounds.width - leftX
        return statusLabel.jv_calculateHeight(forWidth: width)
    }
}
