//
//  PlaceholderViewController.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 27/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

import UIKit
import TypedTextAttributes

struct PlaceholderItem {
    let content: PlaceholderItemContent
    let gap: PlaceholderItemGap
    let scale: CGFloat?
    
    init(content: PlaceholderItemContent, gap: PlaceholderItemGap, scale: CGFloat? = nil) {
        self.content = content
        self.gap = gap
        self.scale = scale
    }
}

enum PlaceholderItemContent {
    case icon(under: UIImage?, over: UIImage?)
    case title(String)
    case body(String)
    case caption(caption: String, colorUsage: JVDesignColorUsage, chevron: Bool, tapHandler: ((UILabel) -> Void)?)
    case button(title: String, tapHandler: ((UIButton) -> Void)?)
}

enum PlaceholderItemGap {
    case auto
    case shortBottom
    case shortTop
}

final class PlaceholderViewController<Satellite: BaseViewControllerSatellite>: StackViewController<Satellite> {
    private let waitingIndicator = UIActivityIndicatorView(style: .jv_auto)
    
    init(satellite: Satellite?, layout: StackViewLayout) {
        super.init(
            satellite: satellite,
            layout: layout,
            fitting: .shortest,
            sideMargin: nil)
        
        scrollView.contentInsetAdjustmentBehavior = .automatic
        
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        
        waitingIndicator.alpha = 0
        waitingIndicator.hidesWhenStopped = false
        
        setDefaultItemInsets(UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
        appendToStack(view: waitingIndicator, insets: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var placeholderItems = [PlaceholderItem]() {
        didSet { regenerateChildren() }
    }

    var extraInsets = UIEdgeInsets.zero {
        didSet { view.setNeedsLayout() }
    }
    
    func startWaiting() {
        waitingIndicator.alpha = 1.0
        waitingIndicator.startAnimating()
    }
    
    func stopWaiting() {
        waitingIndicator.alpha = 0
        waitingIndicator.stopAnimating()
    }
    
    override func viewDidLayoutSubviews() {
        sideMargin = view.bounds.width * 0.1
        super.viewDidLayoutSubviews()
    }
    
    override func stackViewHasHitLogic() -> Bool {
        return true
    }
    
    override func stackView(_ stackView: UIView, hitPoint: CGPoint, event: UIEvent?, fallback: UIView?) -> UIView? {
        guard let fallback = fallback else {
            return nil
        }
        
        for child in stackItems.map(\.view) {
            guard fallback.isDescendant(of: child) else { continue }
            guard child.isUserInteractionEnabled else { continue }
            return fallback
        }
        
        return nil
    }
    
    private func regenerateChildren() {
        cleanupStack()
        appendToStack(view: waitingIndicator, insets: nil)
        
        for item in placeholderItems {
            appendToStack(
                view: jv_convert(item.content) { value in
                    switch value {
                    case let .icon(under, over):
                        return generateIcon(under: under, over: over)
                    case let .title(message):
                        return generateTitle(message: message)
                    case let .body(message):
                        return generateBody(message: message)
                    case let .caption(caption, colorUsage, chevron, tapHandler):
                        return generateCaption(caption: caption, colorUsage: colorUsage, chevron: chevron, tapHandler: tapHandler)
                    case let .button(title, tapHandler):
                        return generateButton(title: title, tapHandler: tapHandler)
                    }
                },
                insets: jv_convert(item.gap) { value in
                    switch value {
                    case .auto:
                        return nil
                    case .shortBottom:
                        return UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
                    case .shortTop:
                        return UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
                    }
                },
                scale: item.scale)
        }
    }
    
    private func generateIcon(under: UIImage?, over: UIImage?) -> UIView {
        let child = StackViewChildIcon()
        child.underImage = under
        child.overImage = over
        return child
    }
    
    private func generateTitle(message: String) -> UIView {
        let attrs = TextAttributes()
            .minimumLineHeight(20)
            .foregroundColor(JVDesign.colors.resolve(usage: .secondaryForeground))
            .font(JVDesign.fonts.resolve(.bold(16), scaling: .body))
            .alignment(.center)
        
        let child = UILabel()
        child.numberOfLines = 0
        child.attributedText = message.attributed(attrs)
        return child
    }
    
    private func generateBody(message: String) -> UIView {
        let attrs = TextAttributes()
            .minimumLineHeight(20)
            .foregroundColor(JVDesign.colors.resolve(usage: .secondaryForeground))
            .font(obtainMessageFont())
            .alignment(.center)
        
        let child = UILabel()
        child.numberOfLines = 0
        child.attributedText = message.attributed(attrs)
        return child
    }
    
    private func generateCaption(caption: String, colorUsage: JVDesignColorUsage, chevron: Bool, tapHandler: ((UILabel) -> Void)?) -> UIView {
        let child = PlaceholderBottomCaption(caption: caption, colorUsage: colorUsage, chevron: chevron, tapHandler: tapHandler)
        return child
    }
    
    private func generateButton(title: String, tapHandler: ((UIButton) -> Void)?) -> UIView {
        let child = PlaceholderBottomButton(title: title, tapHandler: tapHandler)
        return child
    }
}

fileprivate func obtainMessageFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(14), scaling: .subheadline)
}
