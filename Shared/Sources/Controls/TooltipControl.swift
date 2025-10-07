//
//  TooltipControl.swift
//  App
//
//  Created by Yulia Popova on 28.06.2023.
//

import UIKit
import SwiftUI

protocol TooltipControlDelegate: AnyObject {
    func tooltipDidTapInside(_ tipView: TooltipControl)
    func tooltipDidTapOutside(_ tipView: TooltipControl)
    func tooltipHasBeenShown(_ tipView: TooltipControl)
}

final class TooltipControl: UIControl {
    public var configuration: Configuration
    
    struct Configuration {
        var cornerRadius = CGFloat(5)
        var tipHeight = CGFloat(8)
        var tipWidth = CGFloat(20)
        
        var singeTitleFont = JVDesign.fonts.resolve(.regular(14), scaling: .body)
        var titleFont = JVDesign.fonts.resolve(.bold(14), scaling: .body)
        var subtitleFont = JVDesign.fonts.resolve(.regular(14), scaling: .body)
        
        var bodyForegroundColor = JVDesign.colors.resolve(alias: .white)
        var titleForegroundColor = JVDesign.colors.resolve(alias: .white)
        var backgroundColor = JVDesign.colors.resolve(alias: .brightBlue)
        
        var margins = UIEdgeInsets(
            top: 0.0,
            left: 30.0,
            bottom: 5.0,
            right: 30.0
        )
        
        var paddings = UIEdgeInsets(
            top: 10.0,
            left: 17.0,
            bottom: 10.0,
            right: 17.0
        )
        
        var maxWidth = CGFloat(260)
        var showDuration = 0.3
        var dismissDuration = 0.3
    }
    
    private weak var presentingView: UIView?
    private weak var delegate: TooltipControlDelegate?
    private var arrowTip = CGPoint.zero
    private let text: NSAttributedString
    
    private lazy var contentSize: CGSize = { [unowned self] in
        let text = self.text
        var textSize = text.boundingRect(with: CGSize(width: self.configuration.maxWidth, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil).size
        
        return CGSize(
            width: max(self.configuration.tipWidth, ceil(textSize.width)),
            height: ceil(textSize.height)
        )
    }()
    
    private lazy var tipViewSize: CGSize = { [unowned self] in
        var tipViewSize =
        CGSize(
            width: self.contentSize.width + self.configuration.paddings.horizontal + self.configuration.margins.horizontal,
            height: self.contentSize.height + self.configuration.paddings.vertical + self.configuration.margins.vertical + self.configuration.tipHeight)
        return tipViewSize
    }()
    
    public static var globalConfiguration = Configuration()
    
    public init(
        title: String,
        subtitle: String?,
        configuration: Configuration = TooltipControl.globalConfiguration,
        delegate: TooltipControlDelegate
    ) {
        let resultedString = NSMutableAttributedString()
        
        let titleStringAttrs = [
            NSAttributedString.Key.foregroundColor: configuration.titleForegroundColor,
            NSAttributedString.Key.font: subtitle == nil ? configuration.singeTitleFont : configuration.titleFont
        ]
        let titleString = NSAttributedString(
            string: title,
            attributes: titleStringAttrs
        )
        
        resultedString.append(titleString)
        
        if let subtitle = subtitle {
            let subtitleStringAttrs = [
                NSAttributedString.Key.foregroundColor: configuration.bodyForegroundColor,
                NSAttributedString.Key.font: configuration.subtitleFont
            ]
            let subtitleString = NSAttributedString(
                string: subtitle,
                attributes: subtitleStringAttrs
            )
            
            resultedString.append(NSMutableAttributedString(string: "\n"))
            resultedString.append(subtitleString)
        }
        
        self.text = resultedString
        self.configuration = configuration
        self.delegate = delegate
        
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = UIColor.clear
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported. Use init(text, configuration, delegate) instead!")
    }
    
    private func arrange(withinSuperview superview: UIView) {
        guard let presentingView = presentingView else {
            assertionFailure()
            return
        }
        
        let refViewFrame = presentingView.convert(presentingView.bounds, to: superview)
        
        var frame = CGRect(
            x: max(0, refViewFrame.midX - tipViewSize.width / 2),
            y: max(0, refViewFrame.origin.y - tipViewSize.height),
            width: tipViewSize.width,
            height: tipViewSize.height
        )
        
        if frame.maxX > superview.bounds.width {
            frame.origin.x = superview.bounds.width - frame.width
        }
        
        if frame.maxY > superview.bounds.maxY {
            frame.origin.y = superview.bounds.height - frame.height
        }
        
        var arrowTipXOrigin: CGFloat
        
        if frame.width < refViewFrame.width {
            arrowTipXOrigin = tipViewSize.width / 2
        } else {
            arrowTipXOrigin = abs(frame.origin.x - refViewFrame.origin.x) + refViewFrame.width / 2 - configuration.tipWidth / 2
        }
        
        arrowTip = CGPoint(
            x: arrowTipXOrigin,
            y: tipViewSize.height - configuration.margins.bottom
        )
        
        self.frame = frame
    }
    
    @objc private func handleTapInside() {
        self.delegate?.tooltipDidTapInside(self)
    }
    
    @objc private func handleTapOutside() {
        self.delegate?.tooltipDidTapOutside(self)
    }
    
    override public func draw(_ rect: CGRect) {
        let bubbleFrame = getBubbleFrame()
        let textRect = getContentRect(from: bubbleFrame)
        
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        
        let tipWidth = configuration.tipWidth
        let tipHeight = configuration.tipHeight
        let cornerRadius = configuration.cornerRadius
        
        let bubblePath = UIBezierPath(
            roundedRect: CGRect(
                x: bubbleFrame.origin.x,
                y: bubbleFrame.origin.y,
                width: bubbleFrame.width,
                height: bubbleFrame.height
            ),
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        
        arrowTip.y = bubbleFrame.height
        
        let arrowPath = UIBezierPath()
        arrowPath.move(to: arrowTip)
        arrowPath.addCurve(
            to: CGPoint(
                x: arrowTip.x + 0.5 * tipWidth,
                y: arrowTip.y + tipHeight
            ),
            controlPoint1: CGPoint(
                x: arrowTip.x + 0.2 * tipWidth,
                y: arrowTip.y
            ),
            controlPoint2: CGPoint(
                x: arrowTip.x + 0.35 * tipWidth,
                y: arrowTip.y + tipHeight
            )
        )
        
        arrowPath.addLine(
            to: CGPoint(
                x: arrowTip.x + 0.5 * tipWidth,
                y: arrowTip.y + tipHeight
            )
        )
        
        arrowPath.addCurve(
            to: CGPoint(
                x: arrowTip.x + tipWidth,
                y: arrowTip.y
            ),
            controlPoint1: CGPoint(
                x: arrowTip.x + 0.65 * tipWidth,
                y: arrowTip.y + tipHeight
            ),
            controlPoint2: CGPoint(
                x: arrowTip.x + 0.8 * tipWidth,
                y: arrowTip.y
            )
        )
        
        arrowPath.close()
        
        bubblePath.append(arrowPath)
        bubblePath.addClip()
        
        context.setFillColor(configuration.backgroundColor.cgColor)
        context.addPath(bubblePath.cgPath)
        context.fillPath()
        
        text.draw(with: textRect, options: .usesLineFragmentOrigin, context: .none)
        
        context.restoreGState()
    }
    
    private func getBubbleFrame() -> CGRect {
        return CGRect(
            x: configuration.margins.left,
            y: configuration.margins.top,
            width: tipViewSize.width - configuration.margins.left - configuration.margins.right,
            height: tipViewSize.height - configuration.margins.top - configuration.margins.bottom - configuration.tipHeight
        )
    }
    
    private func getContentRect(from bubbleFrame: CGRect) -> CGRect {
        return CGRect(
            x: bubbleFrame.origin.x + configuration.paddings.left,
            y: bubbleFrame.origin.y + configuration.paddings.top,
            width: contentSize.width,
            height: contentSize.height
        )
    }
    
    func show(
        forView view: UIView,
        withinParent superview: UIView,
        configuration: Configuration = TooltipControl.globalConfiguration
    ) {
        self.show(forView: view, withinParent: superview)
    }
    
    private func show(forView view: UIView, withinParent superview: UIView) {
        presentingView = view
        arrange(withinSuperview: superview)
        
        superview.subviews.forEach { currentView in
            if currentView.accessibilityIdentifier == String(view.hash) {
                currentView.removeFromSuperview()
            }
        }
        
        accessibilityIdentifier = String(view.hash)
        
        alpha = 0.0
        
        superview.addSubview(self)
        
        addTarget(self, action: #selector(handleTapInside), for: .touchUpInside)
        
        UIView.animate(
            withDuration: configuration.showDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                self.alpha = 1.0
            },
            completion: nil
        )
        
        self.delegate?.tooltipHasBeenShown(self)
    }
    
    func dismiss() {
        UIView.animate(
            withDuration: configuration.dismissDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                self.alpha = 0.0
            },
            completion: { _ in
                self.removeFromSuperview()
                self.transform = CGAffineTransform.identity
            }
        )
    }
}
