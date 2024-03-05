//
//  StackViewController.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 31/07/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

enum StackViewLayout {
    case top
    case center
}

enum StackViewFitting {
    case full
    case shortest
}

struct StackItem {
    let view: UIView
    let insets: UIEdgeInsets
    let fitting: StackViewFitting
    let scale: CGFloat
    let renderable: Bool
}

class StackViewController<Satellite: BaseViewControllerSatellite>: KeyboardableViewController<Satellite>, StackViewHitDelegate, UIScrollViewDelegate {
    private let layout: StackViewLayout
    private let fitting: StackViewFitting

    let scrollView = UIScrollView()

    private(set) var stackItems = [StackItem]()
    private var defaultMargins = UIEdgeInsets.zero // (top: 20, left: 0, bottom: 20, right: 0)
    private var defaultPaddings = UIEdgeInsets.zero
    private(set) var defaultInsets = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
    private var defaultItemInsets = UIEdgeInsets.zero
    
    init(satellite: Satellite?, layout: StackViewLayout, fitting: StackViewFitting, sideMargin: CGFloat? = nil) {
        self.layout = layout
        self.fitting = fitting
        self.sideMargin = sideMargin ?? 15

        super.init(satellite: satellite)
        
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        
        scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var scrollY = CGFloat(0) {
        didSet { view.setNeedsLayout() }
    }
    
    var sideMargin: CGFloat
    
    var scrollEnabled: Bool {
        get { scrollView.isScrollEnabled }
        set { scrollView.isScrollEnabled = newValue }
    }
    
    override var adjustableScrollView: UIScrollView {
        return scrollView
    }
    
    override var adjustingDefaultInsets: UIEdgeInsets {
        return defaultInsets
    }

    func setDefaultTopMargin(_ top: CGFloat) {
        defaultMargins.top = top
        view.setNeedsLayout()
    }
    
    func setDefaultTopPadding(_ top: CGFloat) {
        defaultPaddings.top = top
        view.setNeedsLayout()
    }
    
    func setDefaultInsets(_ insets: UIEdgeInsets) {
        defaultInsets = insets
    }
    
    func setDefaultItemInsets(_ insets: UIEdgeInsets) {
        defaultItemInsets = insets
    }
    
    func setDefaultBottomMargin(_ bottom: CGFloat) {
        defaultMargins.bottom = bottom
    }

    func appendToStack(view: UIView, insets: UIEdgeInsets?, scale: CGFloat? = nil) {
        let item = StackItem(
            view: view,
            insets: insets ?? defaultItemInsets,
            fitting: fitting,
            scale: scale ?? 1.0,
            renderable: true)
        stackItems.append(item)
        scrollView.addSubview(view)
        self.view.setNeedsLayout()
    }

    func appendToStack(view: UIView, topInset: CGFloat, bottomInset: CGFloat) {
        let insets = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
        appendToStack(view: view, insets: insets)
    }
    
    func updateWithinStack(view: UIView, topInset: CGFloat, bottomInset: CGFloat, scale: CGFloat) {
        guard
            let index = findIndex(child: view)
            else { return }
        
        var insets = stackItems[index].insets
        insets.top = topInset
        insets.bottom = bottomInset
        stackItems[index] = StackItem(view: view, insets: insets, fitting: fitting, scale: scale, renderable: true)
        
        self.view.setNeedsLayout()
    }
    
    func cleanupStack() {
        for item in stackItems {
            item.view.removeFromSuperview()
        }
        
        stackItems.removeAll()
    }
    
    func animateOut(views: [UIView], delay: TimeInterval = 0) {
        UIView.animate(
            withDuration: 0.25,
            delay: delay,
            options: [.allowAnimatedContent, .layoutSubviews],
            animations: {
                views.forEach({ $0.alpha = 0 })
            },
            completion: nil)
        
        UIView.animate(
            withDuration: 0.75,
            delay: delay,
            options: [.allowAnimatedContent, .layoutSubviews],
            animations: { [weak self] in
                guard let `self` = self else { return }
                
                for index in views.compactMap(self.findIndex) {
                    self.stackItems[index] = self.stackItems[index].copy(renderable: false)
                }
                
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            },
            completion: nil)
    }
    
    func animateIn(views: [UIView], delay: TimeInterval = 0) {
        UIView.animate(
            withDuration: 0.75,
            delay: delay,
            options: [.allowAnimatedContent, .layoutSubviews],
            animations: { [weak self] in
                guard let `self` = self else { return }
                
                for index in views.compactMap(self.findIndex) {
                    self.stackItems[index] = self.stackItems[index].copy(renderable: true)
                }
                
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            },
            completion: nil)
        
        UIView.animate(
            withDuration: 0.5,
            delay: delay + 0.25,
            options: [.allowAnimatedContent, .layoutSubviews],
            animations: {
                views.forEach({ $0.alpha = 1.0 })
            },
            completion: nil)
    }
    
    func refreshStack() {
        self.view.setNeedsLayout()
    }
    
    func scrollToVisible() {
        scrollView.scrollRectToVisible(.zero, animated: false)
    }
    
    override func loadView() {
        let stackView = StackView()
        stackView.hitDelegate = self
        view = stackView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(scrollView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let layout = getLayout(size: view.bounds.size)
        scrollView.frame = layout.scrollViewFrame
        scrollView.contentSize = layout.scrollViewContentSize
        zip(stackItems, layout.scrollViewChildrenFrames).forEach { $0.view.frame = $1 }
    }
    
    private func findIndex(child: UIView) -> Int? {
        return stackItems.firstIndex(where: { $0.view === child })
    }

    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            items: stackItems,
            safeAreaInsets: safeAreaInsets,
            scrollY: scrollY,
            layout: layout,
            defaultMargins: defaultMargins,
            defaultPaddings: defaultPaddings,
            sideMargin: sideMargin,
            scrollPosition: scrollView.contentOffset.y,
            keyboardHeight: keyboardHeight)
    }
    
    func stackViewHasHitLogic() -> Bool {
        return false
    }
    
    func stackView(_ stackView: UIView, hitPoint: CGPoint, event: UIEvent?, fallback: UIView?) -> UIView? {
        return nil
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let items: [StackItem]
    let safeAreaInsets: UIEdgeInsets
    let scrollY: CGFloat
    let layout: StackViewLayout
    let defaultMargins: UIEdgeInsets
    let defaultPaddings: UIEdgeInsets
    let sideMargin: CGFloat
    let scrollPosition: CGFloat
    let keyboardHeight: CGFloat

    var scrollViewFrame: CGRect {
        return bounds
    }

    var scrollViewChildrenFrames: [CGRect] {
        let width = bounds.width - sideMargin * 2
        var rect = CGRect(x: sideMargin, y: topContentY, width: width, height: 0)

        return items.map { item in
            if item.view.isHidden {
                rect.size.height = 0

                return rect
            }
            else {
                let itemSize = item.view.jv_size(forWidth: width)
                let height = itemSize.height * item.scale
                
                switch item.fitting {
                case .full:
                    rect.size.width = width
                    rect.origin.x = sideMargin
                case .shortest:
                    rect.size.width = itemSize.width
                    rect.origin.x = sideMargin + (width - itemSize.width) * 0.5
                }
                
                if item.renderable {
                    rect.origin.y += item.insets.top
                    rect.size.height = height

                    defer { rect.origin.y = rect.maxY + item.insets.bottom }
                    return rect
                }
                else {
                    rect.origin.y -= height
                    rect.size.height = height

                    defer { rect.origin.y = rect.maxY }
                    return rect
                }
            }
        }
    }

    var scrollViewContentSize: CGSize {
        let width = bounds.width - sideMargin * 2
        var height = CGFloat(0)

        for item in items {
            guard !item.view.isHidden else { continue }
            guard item.renderable else { continue }
            height += item.view.jv_height(forWidth: width) + item.insets.vertical
        }

        return CGSize(width: bounds.width, height: height + defaultMargins.bottom)
    }

    private var topContentY: CGFloat {
        switch layout {
        case .top:
            return defaultMargins.top
        case .center where keyboardHeight > 0:
            return defaultMargins.top
        case .center:
            let canvasHeight = bounds.height - safeAreaInsets.vertical
            let contentHeight = scrollViewContentSize.height
            let offset = defaultMargins.top + (scrollY + min(0, scrollPosition))
            let result = offset + max(0, canvasHeight * 0.5 - contentHeight * 0.5)
            return max(0, result) + defaultPaddings.top
        }
    }
}

fileprivate extension StackItem {
    func copy(insets: UIEdgeInsets? = nil, scale: CGFloat? = nil, renderable: Bool? = nil) -> StackItem {
        return StackItem(
            view: view,
            insets: insets ?? self.insets,
            fitting: fitting,
            scale: scale ?? self.scale,
            renderable: renderable ?? self.renderable)
    }
}
