//
// Created by Stan Potemkin on 09/08/2018.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

final class JMTimelineMessageLoadingIndicator: UIView {
    let button = TriggerButton(style: .primary, weight: .regular)
    private let indicator = UIActivityIndicatorView(style: .jv_auto)

    init() {
        super.init(frame: .zero)
        
        isOpaque = false
        
        layer.needsDisplayOnBoundsChange = true
        
        button.caption = loc["JV_ChatTimeline_SystemButton_LoadMore", "Chat.History.LoadMore"]
        button.isHidden = true
        addSubview(button)
        
        indicator.isHidden = true
        addSubview(indicator)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showAsButton() {
        hide()
        button.isHidden = false
        isHidden = false
        setNeedsDisplay()
    }
    
    func showAsIndicator() {
        hide()
        indicator.jv_start()
        isHidden = false
        setNeedsDisplay()
    }
    
    func hide() {
        button.isHidden = true
        indicator.jv_stop()
        isHidden = true
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        button.frame = layout.controlFrame
        indicator.frame = layout.controlFrame
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext()
        else {
            return
        }
        
        context.clear(rect)
        context.setFillColor(JVDesign.colors.resolve(usage: .primaryForeground).jv_withAlpha(0.15).cgColor)
        
        let layout = getLayout(size: rect.size)
        layout.decorationFrames.forEach(context.fill)
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            button: button,
            indicator: indicator
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let button: UIButton
    let indicator: UIActivityIndicatorView
    
    private let padding = CGFloat(5)
    private let width = CGFloat(10)
    private let thickness = CGFloat(1)
    private let length = CGFloat(15)
    private let gap = CGFloat(10)
    
    var decorationFrames: [CGRect] {
        return [
            CGRect(
                x: bounds.midX - width * 0.5,
                y: padding,
                width: width,
                height: thickness
            ),
            CGRect(
                x: bounds.midX - thickness * 0.5,
                y: padding + thickness,
                width: thickness,
                height: length
            ),
            CGRect(
                x: bounds.midX - thickness * 0.5,
                y: controlFrame.maxY + gap,
                width: thickness,
                height: length
            ),
            CGRect(
                x: bounds.midX - width * 0.5,
                y: controlFrame.maxY + gap + length,
                width: width,
                height: thickness
            )
        ]
    }
    
    var controlFrame: CGRect {
        let size = CGRect()
            .union(CGRect(origin: .zero, size: button.sizeThatFits(.zero)))
            .union(CGRect(origin: .zero, size: indicator.sizeThatFits(.zero)))
            .size
        
        let leftX = bounds.midX - size.width * 0.5
        return CGRect(x: leftX, y: padding + thickness + length + gap, width: size.width, height: size.height)
    }
    
    var totalSize: CGSize {
        let height = (decorationFrames.last?.maxY).jv_orZero + padding
        return CGSize(width: bounds.width, height: height)
    }
}
