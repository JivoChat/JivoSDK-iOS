//
//  TooltipControl.swift
//  App
//
//  Created by Yulia Popova on 28.06.2023.
//

import UIKit

protocol TooltipControlDelegate: AnyObject {
    func tooltipDidTapInside(_ tipView: TooltipControl)
    func tooltipDidTapOutside(_ tipView: TooltipControl)
    func tooltipHasBeenShown(_ tipView: TooltipControl)
}

final class TooltipControl: UIControl {
    struct Configuration {
        var cornerRadius = CGFloat(5)
        var tipHeight = CGFloat(8)
        var tipWidth = CGFloat(18)
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
    private(set) public var configuration: Configuration
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
        subtitle: String,
        configuration: Configuration = TooltipControl.globalConfiguration,
        delegate: TooltipControlDelegate
    ) {
        
        let titleStringAttrs = [
            NSAttributedString.Key.foregroundColor: JVDesign.colors.resolve(alias: .white),
            NSAttributedString.Key.font: JVDesign.fonts.resolve(.bold(14), scaling: .body)
        ]
        let titleString = NSAttributedString(
            string: title,
            attributes: titleStringAttrs
        )
        
        let subtitleStringAttrs = [
            NSAttributedString.Key.foregroundColor: JVDesign.colors.resolve(alias: .white),
            NSAttributedString.Key.font: JVDesign.fonts.resolve(.regular(14), scaling: .body)
        ]
        let subtitleString = NSAttributedString(
            string: subtitle,
            attributes: subtitleStringAttrs
        )
        
        let resultedString = NSMutableAttributedString()
        resultedString.append(titleString)
        resultedString.append(NSMutableAttributedString(string: "\n"))
        resultedString.append(subtitleString)
        
        self.text = resultedString
        self.configuration = configuration
        self.delegate = delegate
        
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = UIColor.clear
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported. Use init(text, configuration, delegate) instead!")
    }
    
    private func computeFrame(refViewFrame: CGRect, superviewBounds: CGRect) -> CGRect {
        var frame = CGRect(
            x: refViewFrame.midX - tipViewSize.width / 2,
            y: refViewFrame.origin.y - tipViewSize.height,
            width: tipViewSize.width,
            height: tipViewSize.height
        )
        
        frame.origin.x = max(0, frame.origin.x)
        frame.origin.y = max(0, frame.origin.y)

        if frame.maxX > superviewBounds.width {
            frame.origin.x = superviewBounds.width - frame.width
        }
        
        if frame.maxY > superviewBounds.maxY {
            frame.origin.y = superviewBounds.height - frame.height
        }
        
        return frame
    }
    
    private func arrange(withinSuperview superview: UIView) {
        guard let presentingView = presentingView else {
            assertionFailure()
            return
        }
        let refViewFrame = presentingView.convert(presentingView.bounds, to: superview);
        
        let frame = computeFrame(refViewFrame: refViewFrame, superviewBounds: superview.frame)
        
        var arrowTipXOrigin: CGFloat
        if frame.width < refViewFrame.width {
            arrowTipXOrigin = tipViewSize.width / 2
        } else {
            arrowTipXOrigin = abs(frame.origin.x - refViewFrame.origin.x) + refViewFrame.width / 2
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
    
    private func drawBubble(_ bubbleFrame: CGRect, context: CGContext) {
        let tipWidth = configuration.tipWidth
        let tipHeight = configuration.tipHeight
        let cornerRadius = configuration.cornerRadius
        
        let path = CGMutablePath()

        let bubbleRect = CGRect(x: bubbleFrame.origin.x, y: bubbleFrame.origin.y, width: bubbleFrame.width, height: bubbleFrame.height)
                
        path.addPath(CGPath(roundedRect: bubbleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil))

        path.move(to: CGPoint(x: arrowTip.x, y: arrowTip.y))
        path.addLine(to: CGPoint(x: arrowTip.x - tipWidth / 2, y: arrowTip.y - tipHeight))
        path.addLine(to: CGPoint(x: arrowTip.x + tipWidth / 2, y: arrowTip.y - tipHeight))
        path.closeSubpath()
        
        context.addPath(path)
        context.clip()
        
        context.setFillColor(configuration.backgroundColor.cgColor)
        context.fill(bounds)
    }
    
    override public func draw(_ rect: CGRect) {
        let bubbleFrame = getBubbleFrame()
        let textRect = getContentRect(from: bubbleFrame)
        
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        
        drawBubble(bubbleFrame, context: context)
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
    
    class func show(
        forView view: UIView,
        withinParent superview: UIView,
        title: String,
        configuration: Configuration = TooltipControl.globalConfiguration,
        delegate: TooltipControlDelegate
    ) {
        
        let control = TooltipControl(
            title: title,
            subtitle: title,
            configuration: configuration,
            delegate: delegate
        )
        
        control.show(forView: view, withinParent: superview)
    }
    
    func show(forView view: UIView, withinParent superview: UIView) {
        let initialAlpha = 0.0

        presentingView = view
        arrange(withinSuperview: superview)
        
        alpha = initialAlpha
        
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let superview = superview else {
            assertionFailure()
            return
            }
        arrange(withinSuperview: superview)
    }
}
