//
//  JMTimelineMessageCanvas.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMRepicKit
import JMOnetimeCalculator
import JMTimelineKit

struct JMTimelineMessageSenderStyle: JMTimelineStyle {
    let backgroundColor: UIColor
    let foregroundColor: UIColor
    let font: UIFont
    let padding: UIEdgeInsets
    let corner: CGFloat
}

struct JMTimelineCompositeStyle: JMTimelineStyle {
    let senderBackground: UIColor
    let senderColor: UIColor
    let senderFont: UIFont
    let senderPadding: UIEdgeInsets
    let senderCorner: CGFloat
    let borderColor: UIColor?
    let borderWidth: CGFloat?
    let backgroundColor: UIColor?
    let foregroundColor: UIColor
    let statusColor: UIColor
    let statusFont: UIFont
    let timeRegularForegroundColor: UIColor
    let timeOverlayBackgroundColor: UIColor
    let timeOverlayForegroundColor: UIColor
    let timeFont: UIFont
    let deliveryViewTintColor: UIColor
    let reactionStyle: ChatTimelineMessageExtrasReactionStyle
    let contentStyle: JMTimelineStyle
}

enum JMTimelineCompositeRenderMode: Equatable {
    enum BubbleTime { case standalone, compact, inline }
    case bubble(time: BubbleTime)
    
    enum ContentTime { case near, over, omit }
    enum ContentColor { case standard, shaded }
    case content(time: ContentTime, color: ContentColor? = nil)
}

struct JMTimelineMessageRenderOptions {
    let position: JMTimelineItemPosition
    let senderIconOffset: Int
    
    init(
        position: JMTimelineItemPosition = .left,
        senderIconOffset: Int = 0
    ) {
        self.position = position
        self.senderIconOffset = senderIconOffset
    }
}

struct JMTimelineMessageRegionRenderOptions {
    let position: JMTimelineItemPosition
    let contentKind: ChatTimelineSenderType
    let outcomingPalette: ChatTimelineVisualConfig.Palette?
    let isQuote: Bool
    let entireCanvas: Bool
    let isFailure: Bool
    
    init() {
        self.position = .left
        self.contentKind = .client
        self.outcomingPalette = nil
        self.isQuote = false
        self.entireCanvas = false
        self.isFailure = false
    }

    init(
        position: JMTimelineItemPosition,
        contentKind: ChatTimelineSenderType,
        outcomingPalette: ChatTimelineVisualConfig.Palette?,
        isQuote: Bool,
        entireCanvas: Bool,
        isFailure: Bool
    ) {
        self.position = position
        self.contentKind = contentKind
        self.outcomingPalette = outcomingPalette
        self.isQuote = isQuote
        self.entireCanvas = entireCanvas
        self.isFailure = isFailure
    }
}

class JMTimelineMessageCanvas: JMTimelineCanvas {
    let senderIcon = JMRepicView.standard()
    let senderCaption = JMTimelineCompositeSenderLabel()
    let senderMark = JMTimelineCompositeSenderLabel()
    let footer = ChatTimelineContainerFooter()

    private var topEdge: JMTimelineMessageLoadingIndicator?
    private var bottomEdge: JMTimelineMessageLoadingIndicator?

    private var kindID = String()
    private var currentRegions = [JMTimelineMessageCanvasRegion]()

    override init() {
        super.init()
        
        addSubview(senderIcon)
        
        senderCaption.layer.masksToBounds = true
        addSubview(senderCaption)
        
        senderMark.backgroundColor = JVDesign.colors.resolve(usage: .badgeBackground)
        senderMark.textColor = JVDesign.colors.resolve(usage: .oppositeForeground)
        senderMark.padding = UIEdgeInsets(top: 1, left: 4, bottom: 1, right: 4)
        senderMark.layer.cornerRadius = 4
        senderMark.layer.masksToBounds = true
        senderMark.isHidden = true
        addSubview(senderMark)
        
        addSubview(footer)
        
        senderIcon.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleSenderIconTap))
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure(item: JMTimelineItem) {
        super.configure(item: item)
        
        let item = item.convert(to: JMTimelineMessageItem.self)
        
        if item.payload.kindID != kindID {
            if !currentRegions.isEmpty {
                let list = cachedRegions[kindID] ?? Array()
                cachedRegions[kindID] = list + [currentRegions]
            }
            
            kindID = item.payload.kindID
            
            currentRegions.forEach { $0.removeFromSuperview() }
            defer {
                currentRegions.forEach { addSubview($0) }
            }
            
            if var list = cachedRegions[kindID], !list.isEmpty {
                currentRegions = list.removeFirst()
                cachedRegions[kindID] = list
            }
            else {
                currentRegions = item.payload.regionsGenerator()
            }
        }
        
        item.payload.regionsPopulator(currentRegions)
        currentRegions.forEach {
            $0.setNeedsLayout()
        }
        
        populateMeta(item: item)
//        populateBlocks(item: item)
        
        if item.hasLayoutOptions(.groupLastElement) {
            senderIcon.configure(item: item.payload.sender.icon)
            senderIcon.isHidden = false
        }
        else {
            senderIcon.isHidden = true
        }
        
        senderCaption.backgroundColor = item.payload.sender.style.backgroundColor
        senderCaption.textColor = item.payload.sender.style.foregroundColor
        senderCaption.font = item.payload.sender.style.font
        senderCaption.padding = item.payload.sender.style.padding
        senderCaption.layer.cornerRadius = item.payload.sender.style.corner
        
        senderMark.font = item.payload.sender.style.font
        
        if item.logicOptions.contains(.missingHistoryPast) {
//            journal {"D/LMH having[missingHistoryPast], show button for date[\(item.date)]"}
            topEdge = topEdge ?? makeIndicator(selector: #selector(handleTopIndicatorTap))
            topEdge?.showAsButton()
        }
        else if item.logicOptions.contains(.loadingHistoryPast) {
            topEdge = topEdge ?? makeIndicator(selector: #selector(handleTopIndicatorTap))
            topEdge?.showAsIndicator()
        }
        else {
            topEdge?.removeFromSuperview()
            topEdge = nil
        }
        
        if item.logicOptions.contains(.missingHistoryFuture) {
            bottomEdge = bottomEdge ?? makeIndicator(selector: #selector(handleBottomIndicatorTap))
            bottomEdge?.showAsButton()
        }
        else if item.logicOptions.contains(.loadingHistoryFuture) {
            bottomEdge = bottomEdge ?? makeIndicator(selector: #selector(handleBottomIndicatorTap))
            bottomEdge?.showAsIndicator()
        }
        else {
            bottomEdge?.removeFromSuperview()
            bottomEdge = nil
        }

        footer.configure(
            caption: item.payload.footer.caption,
            reactions: item.payload.footer.reactions,
            actions: item.payload.footer.actions)
        
        footer.captionHandler = {
            item.payload.interactor.toggleTranslation(uuid: item.uid)
        }
        
        footer.reactionHandler = { index in
            let reaction = item.payload.footer.reactions[index]
            item.payload.interactor.toggleMessageReaction(uuid: item.uid, emoji: reaction.emoji)
        }
        
        footer.actionHandler = { index in
            let action = item.payload.footer.actions[index]
            item.payload.interactor.performMessageSubaction(uuid: item.uid, actionID: action.ID)
        }
        
        footer.presentReactionsHandler = {
            item.payload.interactor.presentMessageReactions(uuid: item.uid)
        }
    }
    
    func populateBlocks(item: JMTimelineItem) {
        assertionFailure()
    }
    
    func configure(object: JMTimelineInfo, style: JMTimelineStyle, provider: JMTimelineProvider, interactor: JMTimelineInteractor) {
        assertionFailure()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        senderIcon.frame = layout.senderIconFrame
        senderCaption.frame = layout.senderLabelFrame
        senderCaption.textAlignment = layout.senderLabelAlignment
        senderMark.frame = layout.senderMarkFrame
        zip(currentRegions, layout.regionsFrames).forEach { $0.0.frame = $0.1 }
        footer.frame = layout.footerFrame
        topEdge?.frame = layout.topEdgeFrame
        bottomEdge?.frame = layout.bottomEdgeFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        guard let item = item as? JMTimelineMessageItem else {
            preconditionFailure()
        }
        
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            item: item,
            sender: item.payload.sender,
            senderLabel: senderCaption,
            senderMark: senderMark,
            regions: currentRegions,
            regionsGap: 8,
            footer: footer,
            layoutOptions: item.layoutOptions,
            renderOptions: item.payload.renderOptions,
            logicOptions: item.logicOptions,
            topEdge: topEdge,
            bottomEdge: bottomEdge
        )
    }
    
    private func populateMeta(item: JMTimelineItem) {
        let item = item.convert(to: JMTimelineMessageItem.self)
        
        if item.hasLayoutOptions(.groupFirstElement) {
            senderCaption.text = item.payload.sender.name
            
            let mark = item.payload.sender.mark ?? String()
            senderMark.text = mark
            senderMark.isHidden = mark.isEmpty
        }
        else {
            senderCaption.text = nil
            
            senderMark.isHidden = true
        }
    }
    
    override func handleLongPressInteraction(gesture: UILongPressGestureRecognizer) -> JMTimelineContentInteractionResult {
        switch super.handleLongPressInteraction(gesture: gesture) {
        case .incorrect: return .incorrect
        case .handled: return .handled
        case .unhandled where gesture.state == .began: break
        case .unhandled: return .handled
        @unknown default: break
        }
        
        if let item = item as? JMTimelineMessageItem {
            if senderIcon.bounds.contains(gesture.location(in: senderIcon)) {
                item.payload.interactor.senderIconLongPress(item: item)
            }
            else {
                for region in currentRegions {
                    let point = gesture.location(in: region)
                    guard region.bounds.contains(point) else {
                        continue
                    }
                    
                    if region.handleLongPressInteraction(gesture: gesture) == .handled {
                        return .handled
                    }
                }
            }
        }
        
        return .handled
    }
    
    private func makeIndicator(selector: Selector) -> JMTimelineMessageLoadingIndicator {
        let control = JMTimelineMessageLoadingIndicator()
        control.button.addTarget(self, action: selector, for: .touchUpInside)
        insertSubview(control, at: 0)
        return control
    }
    
    @objc func handleSenderIconTap() {
        guard let item = item as? JMTimelineMessageItem else {
            return
        }
        
        item.payload.interactor.senderIconTap(item: item)
    }
    
    @objc private func handleTopIndicatorTap() {
        guard let item = item as? JMTimelineMessageItem else {
            return
        }
        
        item.payload.interactor.requestHistoryPast(item: item)
    }
    
    @objc private func handleBottomIndicatorTap() {
        guard let item = item as? JMTimelineMessageItem else {
            return
        }
        
        item.payload.interactor.requestHistoryFuture(item: item)
    }
}

fileprivate var cachedRegions = [String: Array<[JMTimelineMessageCanvasRegion]>]()

fileprivate struct Layout {
    let bounds: CGRect
    let item: JMTimelineItem
    let sender: JMTimelineItemSender
    let senderLabel: UILabel
    let senderMark: UILabel
    let regions: [UIView]
    let regionsGap: CGFloat
    let footer: ChatTimelineContainerFooter
    let layoutOptions: JMTimelineLayoutOptions
    let renderOptions: JMTimelineMessageRenderOptions
    let logicOptions: JMTimelineLogicOptions
    let topEdge: JMTimelineMessageLoadingIndicator?
    let bottomEdge: JMTimelineMessageLoadingIndicator?

    private let sameGroupingGapCoef = CGFloat(0.2)
    private let iconSize = CGSize(width: 30, height: 30)
    private let iconGap = CGFloat(10)
    private let maximumWidthPercentage = CGFloat(0.93)
    private let gap = CGFloat(5)
    private let timeOuterGap = CGFloat(6)
    
    var senderIconFrame: CGRect {
        if !layoutOptions.contains(.groupLastElement) {
            return .zero
        }
        
        if sender.icon == nil {
            return .zero
        }
        
        let regionBottomEdge = regionsFrames.reversed().prefix(renderOptions.senderIconOffset + 1).last?.maxY ?? bounds.height
        let topY = regionBottomEdge - iconSize.height
        return CGRect(x: 0, y: topY, width: iconSize.width, height: iconSize.height)
    }
    
    private let _senderLabelFrame = JMLazyEvaluator<Layout, CGRect> { s in
        if !s.layoutOptions.contains(.groupFirstElement) {
            return .zero
        }
        
        if s.sender.name == nil {
            return .zero
        }
        
        let containerWidth = s.bounds.width - (s.iconSize.width + s.iconGap)
        let size = s.senderLabel.jv_size(forWidth: containerWidth)
        
        switch s.renderOptions.position {
        case .left:
            let leftX = s.iconHorizontalSpace
            return CGRect(x: leftX, y: s.topEdgeFrame.maxY, width: size.width, height: size.height)
        case .right:
            let leftX = s.bounds.width - size.width
            return CGRect(x: leftX, y: s.topEdgeFrame.maxY, width: size.width, height: size.height)
        }
    }
    
    var senderLabelFrame: CGRect {
        return _senderLabelFrame.value(input: self)
    }
    
    var senderLabelAlignment: NSTextAlignment {
        switch renderOptions.position {
        case .left: return .left
        case .right: return .right
        }
    }
    
    var senderMarkFrame: CGRect {
        let size = senderMark.sizeThatFits(.zero)
        let leftX = senderLabel.jv_hasText ? senderLabelFrame.maxX + 5 : senderLabelFrame.minX
        let topY = senderLabelFrame.midY - size.height * 0.5
        return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
    }
    
    var regionsFrames: [CGRect] {
        var rect = CGRect(
            x: 0,
            y: -regionsGap + (
                senderLabelFrame.height > 0
                ? senderLabelFrame.maxY + gap
                : topEdgeFrame.maxY
            ),
            width: 0,
            height: 0
        )
        
        return regionsSizes.map { size in
            rect = rect.offsetBy(dx: 0, dy: rect.height + regionsGap)
            rect.size = size

            switch renderOptions.position {
            case .left:
                rect.origin.x = iconHorizontalSpace
            case .right:
                rect.origin.x = bounds.width - rect.width
            }
            
            return rect
        }
    }
    
    var footerFrame: CGRect {
        let size = footerSize
        let topY = (regionsFrames.last ?? .zero).maxY + 5
        let width = size.width
        let height = size.height
        
        switch renderOptions.position {
        case .left:
            return CGRect(x: iconHorizontalSpace, y: topY, width: width, height: height)
        case .right:
            return CGRect(x: bounds.width - width, y: topY, width: width, height: height)
        }
    }
    
    var topEdgeFrame: CGRect {
        if logicOptions.isDisjoint(with: [.missingHistoryPast, .loadingHistoryPast]) {
            return bounds.divided(atDistance: 0, from: .minYEdge).slice
        }
        else if let topEdge = topEdge {
            let size = topEdge.jv_size(forWidth: bounds.width)
            return bounds.divided(atDistance: size.height, from: .minYEdge).slice
        }
        else {
            return bounds.divided(atDistance: 0, from: .minYEdge).slice
        }
    }
    
    var bottomEdgeFrame: CGRect {
        if logicOptions.isDisjoint(with: [.missingHistoryFuture, .loadingHistoryFuture]) {
            return bounds.divided(atDistance: 0, from: .maxYEdge).slice
        }
        else if let bottomEdge = bottomEdge {
            let size = bottomEdge.jv_size(forWidth: bounds.width)
            return bounds.divided(atDistance: size.height, from: .maxYEdge).slice
        }
        else {
            return bounds.divided(atDistance: 0, from: .maxYEdge).slice
        }
    }
    
    var totalSize: CGSize {
        let senderHeight: CGFloat
        if let _ = senderLabel.text {
            senderHeight = senderLabelFrame.height + gap
        }
        else {
            senderHeight = 0
        }
        
        let regionsHeight = regionsSizes.map(\.height).reduce(0, +)
        let regionsGaps = max(0, regionsGap * CGFloat(regionsSizes.count - 1))
        
        let footerHeight: CGFloat
        if footerSize.height > 0 {
            footerHeight = footerSize.height + 6
        }
        else {
            footerHeight = 0
        }
        
        let height = (
            topEdgeFrame.height +
            senderHeight +
            regionsHeight +
            regionsGaps +
            footerHeight +
            bottomEdgeFrame.height
        )
        
        return CGSize(width: bounds.width, height: height)
    }
    
    private var maximumRegionWidth: CGFloat {
        return (bounds.width - iconHorizontalSpace) * maximumWidthPercentage
    }
    
    private let _regionsSizes = JMLazyEvaluator<Layout, [CGSize]> { s in
        return s.regions.map { region in
            region.jv_size(forWidth: s.maximumRegionWidth)
        }
    }
    
    private var regionsSizes: [CGSize] {
        return _regionsSizes.value(input: self)
    }
    
    private var footerSize: CGSize {
        let originWidth = bounds.width - iconHorizontalSpace * 2
        return footer.jv_size(forWidth: originWidth)
    }
    
    private var iconHorizontalSpace: CGFloat {
        return iconSize.width + iconGap
    }
}
