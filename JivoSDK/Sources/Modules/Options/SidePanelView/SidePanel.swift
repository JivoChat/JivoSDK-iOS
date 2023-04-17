//
//  SidePanel.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 06.12.2020.
//

import UIKit
#if canImport(JivoFoundation)
import JivoFoundation
#endif


fileprivate let ANIMATION_DURATION: TimeInterval = 0.25
fileprivate let BACKDROP_ALPHA: CGFloat = 0.5

fileprivate let backdropView = UIView()

protocol SidePanel where Self: UIView {
    
    func present(withAnimationDuration animationDuration: TimeInterval, completion: (() -> Void)?)
    func dismiss(withAnimationDuration animationDuration: TimeInterval, completion: (() -> Void)?)
}

extension SidePanel {
    
    func present(withAnimationDuration animationDuration: TimeInterval = ANIMATION_DURATION, completion: (() -> Void)? = nil) {
        let targetY = self.frame.origin.y - self.frame.height
        slideTo(yCoordinate: targetY, completion: completion)
        animateBackdrop(toPresent: true)
    }
    
    func dismiss(withAnimationDuration animationDuration: TimeInterval = ANIMATION_DURATION, completion: (() -> Void)? = nil) {
        let targetY = self.frame.origin.y + self.frame.height
        slideTo(yCoordinate: targetY, completion: completion)
        animateBackdrop(toPresent: false)
    }
    
    private func slideTo(yCoordinate targetY: CGFloat, withAnimationDuration animationDuration: TimeInterval = ANIMATION_DURATION, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: animationDuration, animations: { [weak self] in
            guard let `self` = self else { return }
            
            self.frame = CGRect(
                x: self.frame.origin.x,
                y: targetY,
                width: self.frame.width,
                height: self.frame.height
            )
        },
        completion: { _ in
            completion?()
        })
    }
    
    private func animateBackdrop(toPresent isPresenting: Bool) {
        backdropView.frame = superview?.frame ?? CGRect()
        backdropView.backgroundColor = JVDesign.colors.resolve(usage: .focusingShadow).jv_withAlpha(BACKDROP_ALPHA)
        if isPresenting {
            backdropView.removeFromSuperview()
            superview?.insertSubview(backdropView, belowSubview: self)
        }
        
        UIView.animate(withDuration: ANIMATION_DURATION, delay: 0, options: [.transitionCrossDissolve], animations: {
            backdropView.isHidden = !(isPresenting)
        })
    }
}
