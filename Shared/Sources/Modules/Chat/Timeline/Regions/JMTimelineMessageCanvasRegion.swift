//
//  JMTimelineMessageCanvasRegion.swift
//  JMTimelineKit
//
//  Created by Stan Potemkin on 09.12.2021.
//

import Foundation
import UIKit
import MapKit
import JMOnetimeCalculator
import JMTimelineKit


struct JMTimelineMessageMeta {
    let timepoint: String
    let delivery: JMTimelineItemDelivery
    let status: String
    
    init(
        timepoint: String,
        delivery: JMTimelineItemDelivery,
        status: String
    ) {
        self.timepoint = timepoint
        self.delivery = delivery
        self.status = status
    }
}

class JMTimelineMessageCanvasRegion: UIView, JMTimelineStylable {
    let quoteControl = UIView()
    let decorationView = UIImageView()
    let timeLabel = UILabel()
    let deliveryView = JMTimelineDeliveryView()
    let statusLabel = UILabel()

    private let renderMode: JMTimelineCompositeRenderMode
    private(set) var currentUid = String()
    private(set) var currentInfo: Any?
    private var renderOptions = JMTimelineMessageRegionRenderOptions()
    private var contentKind = ChatTimelineSenderType.neutral
    private(set) var provider: JVChatTimelineProvider?
    private(set) var interactor: JVChatTimelineInteractor?
    
    private var currentBlocks = [UIView & JMTimelineBlockCallable]()
    
    init(renderMode: JMTimelineCompositeRenderMode, masksToBounds: Bool = true) {
        self.renderMode = renderMode
        
        super.init(frame: .zero)
        
        quoteControl.backgroundColor = JVDesign.colors.resolve(usage: .quoteMark)
        quoteControl.layer.masksToBounds = true
        addSubview(quoteControl)
        
        decorationView.layer.masksToBounds = masksToBounds
        decorationView.isUserInteractionEnabled = true
        addSubview(decorationView)
        
        statusLabel.font = JVDesign.fonts.resolve(.regular(12), scaling: .caption1)
        statusLabel.textColor = JVDesign.colors.resolve(usage: .secondaryForeground)
        addSubview(statusLabel)
        
        timeLabel.font = JVDesign.fonts.resolve(.regular(12), scaling: .caption1)
        timeLabel.layer.masksToBounds = true
        addSubview(timeLabel)
        
        deliveryView.contentMode = .right
        addSubview(deliveryView)
        
        updateDesign()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(uid: String, info: Any, meta: JMTimelineMessageMeta?, options: JMTimelineMessageRegionRenderOptions, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        self.currentUid = uid
        self.currentInfo = info
        self.renderOptions = options
        self.contentKind = options.contentKind
        self.provider = provider
        self.interactor = interactor
        
        updateDesign()
        
        if let meta = meta {
            timeLabel.text = meta.timepoint
            timeLabel.isHidden = false
            
            deliveryView.configure(delivery: meta.delivery)
            deliveryView.isHidden = false
            
            statusLabel.text = meta.status
            statusLabel.isHidden = false
        }
        else {
            timeLabel.isHidden = true
            deliveryView.isHidden = true
            statusLabel.isHidden = true
        }
    }
    
    func updateDesign() {
        switch contentKind {
        case .client:
            decorationView.image = generateBackground(color: renderOptions.outcomingPalette?.backgroundColor ?? JVDesign.colors.resolve(usage: .clientBackground))
            timeLabel.textColor = renderOptions.outcomingPalette?.foregroundColor ?? JVDesign.colors.resolve(usage: .clientTime).jv_withAlpha(0.6)
            deliveryView.tintColor = JVDesign.colors.resolve(usage: .clientCheckmark).withAlphaComponent(0.6)
            
        case .agent:
            decorationView.image = generateBackground(color: JVDesign.colors.resolve(usage: .agentBackground))
            timeLabel.textColor = JVDesign.colors.resolve(usage: .agentTime).jv_withAlpha(0.6)
            deliveryView.tintColor = JVDesign.colors.resolve(alias: .greenJivo)
            
        case .comment:
            decorationView.image = generateBackground(color: JVDesign.colors.resolve(usage: .commentBackground))
            timeLabel.textColor = JVDesign.colors.resolve(usage: .agentTime).jv_withAlpha(0.6)
            deliveryView.tintColor = JVDesign.colors.resolve(alias: .greenJivo)
            
        case .bot:
            decorationView.image = generateBackground(color: JVDesign.colors.resolve(usage: .agentBackground))
            timeLabel.textColor = JVDesign.colors.resolve(usage: .agentTime).jv_withAlpha(0.6)
            deliveryView.tintColor = JVDesign.colors.resolve(alias: .greenJivo)
            
        case .info:
            decorationView.image = generateBackground(color: JVDesign.colors.resolve(usage: .agentBackground))
            timeLabel.textColor = JVDesign.colors.resolve(usage: .secondaryForeground)
            deliveryView.tintColor = JVDesign.colors.resolve(alias: .greenJivo)
            
        case .call:
            decorationView.image = generateBackground(color: JVDesign.colors.resolve(usage: .primaryBackground))
            timeLabel.textColor = JVDesign.colors.resolve(usage: .secondaryForeground)
            deliveryView.tintColor = JVDesign.colors.resolve(alias: .greenJivo)
            
        case .story:
            decorationView.image = generateBackground(color: JVDesign.colors.resolve(usage: .mediaPlaceholderBackground))
            timeLabel.textColor = JVDesign.colors.resolve(usage: .secondaryForeground)
            deliveryView.tintColor = JVDesign.colors.resolve(usage: .clientCheckmark).withAlphaComponent(0.6)
            
        case .neutral:
            decorationView.image = nil
            timeLabel.textColor = JVDesign.colors.resolve(usage: .secondaryForeground)
            deliveryView.tintColor = JVDesign.colors.resolve(alias: .grayLight) // greenJivo
        }
        
        switch renderMode {
        case .content(time: .over) where renderOptions.isFailure:
            timeLabel.backgroundColor = JVDesign.colors.resolve(usage: .oppositeBackground).jv_withAlpha(0.35)
            timeLabel.textColor = JVDesign.colors.resolve(usage: .warningForeground)
            timeLabel.textAlignment = .center
            
        case .content(time: .over):
            timeLabel.backgroundColor = JVDesign.colors.resolve(usage: .oppositeBackground).jv_withAlpha(0.35)
            timeLabel.textColor = JVDesign.colors.resolve(usage: .oppositeForeground).jv_withAlpha(0.85)
            timeLabel.textAlignment = .center
            
        case .bubble where renderOptions.isFailure, .content where renderOptions.isFailure:
            timeLabel.backgroundColor = UIColor.clear
            timeLabel.textColor = JVDesign.colors.resolve(usage: .warningForeground)
            timeLabel.textAlignment = .right
            
        case .bubble, .content:
            timeLabel.backgroundColor = UIColor.clear
            timeLabel.textAlignment = .right
        }
    }
    
    func integrateBlocks(_ blocks: [UIView & JMTimelineBlockCallable], gap: CGFloat) {
        currentBlocks.forEach { $0.removeFromSuperview() }
        currentBlocks = blocks
        currentBlocks.forEach { decorationView.addSubview($0) }
        
        childrenGap = gap
    }
    
    var childrenGap = CGFloat(0)
    
    var isEmpty: Bool {
        return currentBlocks.isEmpty
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineCompositeStyle.self)
//
//        decorationView.backgroundColor = nil
//        decorationView.layer.borderColor = style.borderColor?.cgColor
//        decorationView.layer.borderWidth = style.borderWidth ?? 0
//
//        statusLabel.textColor = style.statusColor
//        statusLabel.font = style.statusFont
//
//        deliveryView.tintColor = style.deliveryViewTintColor
//
//        if renderMode == .contentBehindTime {
//            timeLabel.backgroundColor = style.timeOverlayBackgroundColor
//            timeLabel.textColor = style.timeOverlayForegroundColor
//            timeLabel.font = style.timeFont
//            timeLabel.textAlignment = .center
//        }
//        else {
//            timeLabel.backgroundColor = UIColor.clear
//            timeLabel.textColor = style.timeRegularForegroundColor
//            timeLabel.font = style.timeFont
//            timeLabel.textAlignment = .right
//        }
//
//        footer.apply(style: style.reactionStyle)
//    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        quoteControl.frame = layout.quoteControlFrame
        quoteControl.layer.cornerRadius = layout.quoteControlRadius
        decorationView.frame = layout.decorationViewFrame
        decorationView.layer.cornerRadius = layout.backgroundViewCornerRadius
        statusLabel.frame = layout.statusLabelFrame
        timeLabel.frame = layout.timeLabelFrame
        timeLabel.layer.cornerRadius = layout.timeLabelCornerRadius
        deliveryView.frame = layout.deliveryViewFrame
        zip(currentBlocks, layout.childrenFrames).forEach { $0.0.frame = $0.1 }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDesign()
    }
    
    func generateBackground(color: UIColor) -> UIImage? {
        let cornerRadius: CGFloat = 16
        let size = CGSize(width: cornerRadius * 2 + 1, height: cornerRadius * 2 + 1)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        defer { UIGraphicsEndImageContext() }
        
        context?.setFillColor(color.cgColor)
        
        let fillRect = CGRect(origin: .zero, size: size)
        let fillPath = UIBezierPath(roundedRect: fillRect, cornerRadius: cornerRadius)
        context?.addPath(fillPath.cgPath)
        context?.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        let caps = UIEdgeInsets(top: cornerRadius + 1, left: cornerRadius + 1, bottom: cornerRadius + 1, right: cornerRadius + 1)
        return image?.resizableImage(withCapInsets: caps)
    }
    
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//
//        if let style = style?.convert(to: JMTimelineCompositeStyle.self) {
//            decorationView.image = style.backgroundColor.flatMap(getBackground)
//        }
//    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            timeLabel: timeLabel,
            deliveryView: deliveryView,
            statusLabel: statusLabel,
            blocks: currentBlocks,
            blocksGap: childrenGap,
            renderMode: renderMode,
            renderOptions: renderOptions
        )
    }
    
    func handleLongPressInteraction(gesture: UILongPressGestureRecognizer) -> JMTimelineContentInteractionResult {
        for block in currentBlocks {
            guard block.bounds.contains(gesture.location(in: block)) else { continue }
            guard block.handleLongPressGesture(recognizer: gesture) else { continue }
            return .handled
        }
        
        if decorationView.bounds.contains(gesture.location(in: decorationView)) {
            interactor?.constructMenuForMessage(uuid: currentUid, container: decorationView)
            return .handled
        }

        return .handled
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let timeLabel: UILabel
    let deliveryView: UIView
    let statusLabel: UILabel
    let blocks: [UIView]
    let blocksGap: CGFloat
    let renderMode: JMTimelineCompositeRenderMode
    let renderOptions: JMTimelineMessageRegionRenderOptions
    
    private let sameGroupingGapCoef = CGFloat(0.2)
    private let maximumWidthPercentage = CGFloat(0.93)
    private let gap = CGFloat(5)
    private let timeOuterGap = CGFloat(6)
    
    var quoteControlFrame: CGRect {
        if renderOptions.isQuote {
            return CGRect(x: 0, y: 0, width: 4, height: bounds.height)
        }
        else {
            return .zero
        }
    }
    
    var quoteControlRadius: CGFloat {
        if renderOptions.isQuote {
            let frame = quoteControlFrame
            return min(frame.width, frame.height) * 0.5
        }
        else {
            return .zero
        }
    }
    
    var decorationViewFrame: CGRect {
        let size = containerSize
        return CGRect(x: quoteControlSpace, y: 0, width: size.width, height: size.height)
    }
    
    var backgroundViewCornerRadius: CGFloat {
        return 8
    }
    
    private var quoteControlSpace: CGFloat {
        if renderOptions.isQuote {
            return quoteControlFrame.maxX + 12
        }
        else {
            return 0
        }
    }
    
    var statusLabelFrame: CGRect {
        let size = statusSize
        let topY = timeLabelFrame.midY - size.height * 0.5
        return CGRect(x: contentInsets.left, y: topY, width: size.width, height: size.height)
    }
    
    var timeLabelFrame: CGRect {
        let size = timeSize
        let leftX = decorationViewFrame.maxX - timeInsets.right - size.width
        let topY = decorationViewFrame.maxY - timeInsets.bottom - size.height
        let base = CGRect(x: leftX, y: topY, width: size.width, height: size.height)
        
        switch (renderMode, renderOptions.position) {
        case (.bubble, _):
            return base
        case (.content(time: .omit), _):
            return base.divided(atDistance: 0, from: .maxXEdge).slice
        case (.content(time: .over), _):
            return base
        case (.content(time: .near), .left):
            return base.offsetBy(dx: -leftX + decorationViewFrame.maxX + 8, dy: 0)
        case (.content(time: .near), .right):
            return base.offsetBy(dx: -leftX + decorationViewFrame.minX - 8 - size.width, dy: 0)
        }
    }
    
    var timeLabelCornerRadius: CGFloat {
        return timeLabelFrame.height * 0.5
    }
    
    var deliveryViewFrame: CGRect {
        let size = deliverySize
        let leftX = timeLabelFrame.minX - gap - size.width
        let topY = timeLabelFrame.midY - size.height * 0.5
        return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
    }
    
    var childrenFrames: [CGRect] {
        var rect = CGRect(
            x: contentInsets.left,
            y: contentInsets.top - blocksGap,
            width: 0,
            height: 0)
        
        return childrenSizes.map { size in
            rect = rect.offsetBy(dx: 0, dy: rect.height + blocksGap)
            rect.size = size
            return rect
        }
    }
    
    var totalSize: CGSize {
        let timeHeight: CGFloat
        if let _ = timeLabel.text {
            timeHeight = timeSize.height + timeInsets.vertical
        }
        else {
            timeHeight = contentInsets.top - contentInsets.bottom
        }
        
        let contentInsetsHeight: CGFloat
        let coveringMetaHeight: CGFloat
        switch renderMode {
        case .bubble(.compact), .bubble(time: .inline):
            contentInsetsHeight = contentInsets.vertical
            coveringMetaHeight = max(statusSize.height, timeHeight)
        case .content:
            contentInsetsHeight = 0
            coveringMetaHeight = 0
        case .bubble(.standalone):
            contentInsetsHeight = 0
            coveringMetaHeight = max(statusSize.height, timeHeight)
        }
        
        let width = max(
            childrenSize.width,
            timeSize.width + timeInsets.horizontal + gap + deliverySize.width + statusSize.width
        )
        
        let height = (
            childrenSize.height +
            contentInsetsHeight +
            coveringMetaHeight
        )
        
        return CGSize(
            width: quoteControlSpace + width + contentInsets.horizontal,
            height: height
        )
    }
    
    private var contentInsets: UIEdgeInsets {
        switch renderMode {
        case .bubble(time: .standalone):
            return UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        case .bubble(time: .compact):
            return UIEdgeInsets(top: 14, left: 14, bottom: 0, right: 14)
        case .bubble(time: .inline):
            return UIEdgeInsets(top: 14, left: 14, bottom: 0, right: 14)
        case .content(time: .over):
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        case .content(time: .near):
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        case .content(time: .omit):
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    private var timeInsets: UIEdgeInsets {
        switch renderMode {
        case .bubble(time: .standalone):
            return UIEdgeInsets(top: 6, left: 6, bottom: 8, right: 8)
        case .bubble(time: .compact):
            return UIEdgeInsets(top: 6, left: 6, bottom: 8, right: 8)
        case .bubble(time: .inline):
            return UIEdgeInsets(top: 0, left: 6, bottom: 8, right: 8)
        case .content(time: .over):
            return UIEdgeInsets(top: 0, left: 2, bottom: 2, right: 2)
        case .content(time: .near):
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        case .content(time: .omit):
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    private let _childrenSizes = JMLazyEvaluator<Layout, [CGSize]> { s in
        let widths: [CGFloat] = s.blocks.map { child in
            return child.jv_size(forWidth: s.bounds.width - s.contentInsets.horizontal).width
        }
        
        let minimalWidth: CGFloat?
        if s.renderOptions.entireCanvas {
            minimalWidth = s.minimalContainerWidth
        }
        else {
            minimalWidth = nil
        }
        
        let maximumWidth: CGFloat
        if let minimalWidth = minimalWidth {
            maximumWidth = max(minimalWidth, widths.max() ?? 0)
        }
        else {
            maximumWidth = widths.max() ?? 0
        }
        
        return s.blocks
            .map { child in
                let height = child.jv_size(forWidth: maximumWidth).height
                return CGSize(width: maximumWidth, height: height)
            }
            .filter { size in
                size.height > 0
            }
    }
    
    private var childrenSizes: [CGSize] {
        return _childrenSizes.value(input: self)
    }
    
    private var childrenSize: CGSize {
        let sizes = childrenSizes
        let gaps = blocksGap * CGFloat(sizes.count - 1)
        let maximumWidth = sizes.map({ $0.width }).max() ?? 0
        let totalHeight = sizes.map({ $0.height }).reduce(0, +) + gaps
        return CGSize(width: maximumWidth, height: totalHeight)
    }
    
    private let _containerSize = JMLazyEvaluator<Layout, CGSize> { s in
        let timeHeight: CGFloat
        if s.renderOptions.entireCanvas {
            timeHeight = 0
        }
        else if let _ = s.timeLabel.text {
            timeHeight = s.timeSize.height + s.timeInsets.vertical
        }
        else {
            timeHeight = s.contentInsets.top - s.contentInsets.bottom
        }
        
        let metaWidth = s.statusSize.width + s.gap + s.deliverySize.width + s.timeInsets.horizontal + s.timeSize.width
        let contentWidth = max(s.childrenSize.width, metaWidth) + s.contentInsets.horizontal
        
        let baseHeight = s.childrenSize.height
        
        let contentInsetsHeight: CGFloat
        let coveringTimeHeight: CGFloat
        switch s.renderMode {
        case .bubble(.compact), .bubble(.inline):
            contentInsetsHeight = s.contentInsets.vertical
            coveringTimeHeight = max(s.statusSize.height, timeHeight)
        case .content:
            contentInsetsHeight = 0
            coveringTimeHeight = 0
        default:
            contentInsetsHeight = 0
            coveringTimeHeight = max(s.statusSize.height, timeHeight)
        }
        
        return CGSize(
            width: contentWidth,
            height: baseHeight + contentInsetsHeight + coveringTimeHeight
        )
    }
    
    private var containerSize: CGSize {
        return _containerSize.value(input: self)
    }
    
    private var statusSize: CGSize {
        return statusLabel.jv_size(forWidth: bounds.width)
    }
    
    private var deliverySize: CGSize {
        return CGSize(width: 15, height: 14)
    }
    
    private var timeSize: CGSize {
        let size = timeLabel.jv_size(forWidth: bounds.width)
        
        switch renderMode {
        case .content(time: .over):
            return CGSize(width: size.width + size.height * 0.5, height: size.height)
        default:
            return size
        }
    }
    
    private var minimalContainerWidth: CGFloat {
        if let _ = timeLabel.text {
            return deliverySize.width + gap + timeSize.width + timeInsets.horizontal + statusSize.width
        }
        else {
            return 0
        }
    }
}
