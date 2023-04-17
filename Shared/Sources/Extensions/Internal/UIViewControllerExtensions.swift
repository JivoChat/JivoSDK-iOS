//
//  UIViewControllerExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 24/10/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

private var kIsAnimatingKey = "is_animating"

enum RootTransitionMode {
    case replace
    case present
    case dismiss
}

fileprivate struct RootTransitionContext {
    let container: UIView
    let oldView: UIView?
    let newView: UIView?
}

extension UIViewController {
    var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        }
        else {
            let top = topLayoutGuide.length
            let bottom = bottomLayoutGuide.length
            return UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        }
    }
    
    var readableAreaInsets: UIEdgeInsets {
        let outerBounds = view.bounds
        let innerFrame = view.readableContentGuide.layoutFrame
        
        return UIEdgeInsets(
            top: innerFrame.minY - outerBounds.minY,
            left: innerFrame.minX - outerBounds.minX,
            bottom: (outerBounds.maxY == innerFrame.maxY ? 10 : outerBounds.maxY - innerFrame.maxY),
            right: outerBounds.maxX - innerFrame.maxX
        )
    }
    
    var isVisible: Bool {
        return (viewIfLoaded?.window != nil)
    }

    var isAnimating: Bool {
        get {
            if let object = objc_getAssociatedObject(self, &kIsAnimatingKey) as? NSNumber {
                return object.boolValue
            }
            else {
                return false
            }
        }
        set {
            objc_setAssociatedObject(
                self,
                &kIsAnimatingKey,
                NSNumber(booleanLiteral: newValue),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    func setActiveViewController(_ viewController: UIViewController?, transition: RootTransitionMode) {
        guard viewController !== children.last else { return }
        let lastViewController = children.last

        isAnimating = true

        let context = RootTransitionContext(
            container: view,
            oldView: lastViewController?.view,
            newView: viewController?.view
        )

        if let viewController = viewController {
            addChild(viewController)
            view.addSubview(viewController.view)
        }

        switch transition {
        case .replace: placeBeforeReplace(context: context)
        case .present: placeBeforePresent(context: context)
        case .dismiss: placeBeforeDismiss(context: context)
        }

        UIView.transition(
            with: view.window ?? view,
            duration: (transition == .replace ? 0 : 0.25),
            options: [],
            animations: { [unowned self] in
                switch transition {
                case .replace: self.animateToReplace(context: context)
                case .present: self.animateToPresent(context: context)
                case .dismiss: self.animateToDismiss(context: context)
                }
            },
            completion: { [weak self] _ in
                lastViewController?.view.removeFromSuperview()
                lastViewController?.removeFromParent()

                self?.isAnimating = false
            }
        )
    }

    func layoutActiveViewController() {
        guard !isAnimating else { return }
        children.last?.view.frame = view.bounds
    }

    private func placeBeforeReplace(context: RootTransitionContext) {
        guard let newView = context.newView else { return }
        context.newView?.frame = context.container.bounds
        context.container.bringSubviewToFront(newView)
    }

    private func animateToReplace(context: RootTransitionContext) {
    }

    private func placeBeforePresent(context: RootTransitionContext) {
        guard let newView = context.newView else { return }
        let offset = context.container.bounds.height
        context.newView?.frame = context.container.bounds.offsetBy(dx: 0, dy: offset)
        context.container.bringSubviewToFront(newView)
    }

    private func animateToPresent(context: RootTransitionContext) {
        context.newView?.frame = context.container.bounds
    }

    private func placeBeforeDismiss(context: RootTransitionContext) {
        guard let newView = context.newView else { return }
        context.newView?.frame = context.container.bounds
        context.container.sendSubviewToBack(newView)
    }

    private func animateToDismiss(context: RootTransitionContext) {
        let offset = context.container.bounds.height
        context.oldView?.frame = context.container.bounds.offsetBy(dx: 0, dy: offset)
    }
}
