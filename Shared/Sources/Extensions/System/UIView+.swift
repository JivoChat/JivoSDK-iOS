//
//  UIViewExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 20/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    enum JVPinMode {
        case bottomFlexible
        case bottomCentered
    }
    
    static func jv_ofHeight(_ height: CGFloat) -> UIView {
        let view = UIView()
        view.frame.size.height = height
        return view
    }
    
    var jv_isVisible: Bool {
        return !isHidden
    }
    
    var jv_safeInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return safeAreaInsets
        }
        else {
            return .zero
        }
    }
    
    var jv_maximumCornerRadius: CGFloat {
        return min(bounds.width, bounds.height) * 0.5
    }
    
    func jv_isAttached() -> Bool {
        return (window != nil)
    }
    
    func jv_size(forWidth width: CGFloat) -> CGSize {
        let containerSize = CGSize(width: width, height: .infinity)
        let result = sizeThatFits(containerSize)
        return result
    }
    
    func jv_height(forWidth width: CGFloat) -> CGFloat {
        return jv_size(forWidth: width).height
    }
    
    func jv_sizedToFit() -> UIView {
        sizeToFit()
        return self
    }
    
    func jv_pin(view: UIView, mode: JVPinMode) {
        switch mode {
        case .bottomFlexible:
            let height = view.bounds.height
            
            view.frame = CGRect(
                x: 0,
                y: bounds.height - height,
                width: bounds.width,
                height: height
            )
            
            view.autoresizingMask = [
                .flexibleTopMargin,
                .flexibleWidth
            ]
            
        case .bottomCentered:
            let width = view.bounds.width
            let height = view.bounds.height
            
            view.frame = CGRect(
                x: (bounds.width - width) * 0.5,
                y: bounds.height - height,
                width: width,
                height: height
            )
            
            view.autoresizingMask = [
                .flexibleTopMargin,
                .flexibleLeftMargin,
                .flexibleRightMargin
            ]
        }
        
        addSubview(view)
    }
    
    func jv_applyFrame(_ frame: CGRect) {
        guard transform == .identity else { return }
        self.frame = frame
    }
    
    func jv_calculateInsets(downto subview: UIView?) -> UIEdgeInsets {
        guard let subview = subview else { return .zero }
        
        return UIEdgeInsets(
            top: subview.frame.minY,
            left: subview.frame.minX,
            bottom: bounds.maxY - subview.frame.maxY,
            right: bounds.maxX - subview.frame.maxX
        )
    }

    func jv_forceLayout() {
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    enum JVFlashAnchor {
        case local
        case parent
    }
    
    func jv_flash(color: UIColor, radius: CGFloat, extendBy: CGVector, anchor: JVFlashAnchor) {
        let flasher = UIView()
        flasher.backgroundColor = color
        flasher.frame = bounds.insetBy(dx: -extendBy.dx, dy: -extendBy.dy)
        flasher.alpha = 0
        flasher.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        flasher.layer.cornerRadius = radius
        flasher.layer.masksToBounds = true
        flasher.layer.zPosition = 999
        
        switch anchor {
        case .local:
            flasher.frame = bounds.insetBy(dx: -extendBy.dx, dy: -extendBy.dy)
            addSubview(flasher)
        case .parent:
            flasher.frame = frame.insetBy(dx: -extendBy.dx, dy: -extendBy.dy)
            superview?.addSubview(flasher)
        }
        
        func _perform(alpha: CGFloat, completion: @escaping () -> Void) {
            UIView.animate(
                withDuration: 0.15,
                animations: { flasher.alpha = alpha },
                completion: { _ in completion() })
        }
        
        _perform(alpha: 1.0) {
            _perform(alpha: 0, completion: flasher.removeFromSuperview)
        }
    }
    
    func jv_animateGlow(delay: Double) {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1.3, y: 0.05)
        gradient.frame = CGRect(x: 0, y: 0, width: bounds.size.width*3, height: bounds.size.height)

        let lowerAlpha: CGFloat = 0.4
        let solid = UIColor(white: 1, alpha: 1).cgColor
        let clear = UIColor(white: 1, alpha: lowerAlpha).cgColor
        gradient.colors     = [ solid, solid, clear, clear, solid, solid ]
        gradient.locations  = [ 0,     0.3,   0.45,  0.55,  0.7,   1     ]

        let theAnimation : CABasicAnimation = CABasicAnimation(keyPath: "transform.translation.x")
        theAnimation.beginTime = CACurrentMediaTime() + delay
        theAnimation.duration = 0.75
        theAnimation.repeatCount = 1
        theAnimation.autoreverses = false
        theAnimation.isRemovedOnCompletion = true
        theAnimation.fillMode = CAMediaTimingFillMode.forwards
        theAnimation.fromValue = -bounds.size.width * 2
        theAnimation.toValue = 0
        gradient.add(theAnimation, forKey: "animateGlow")

        layer.mask = gradient
    }
    
    func jv_discardGlow() {
        layer.mask = nil
    }
    
    func jv_startShimming() {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)

        func _generateLocations(delta: CGFloat) -> [NSNumber] {
            return [0, 0.2, 0.45, 0.55, 0.8, 1].map { NSNumber(value: $0 + delta) }
        }
        
        let solid = UIColor.white.withAlphaComponent(0).cgColor
        let clear = UIColor.white.cgColor
        gradient.colors = [ solid, solid, clear, clear, solid, solid ]
        gradient.locations = _generateLocations(delta: 0)
        layer.mask = gradient

        let shimmingAnimation = CABasicAnimation(keyPath: "locations")
        shimmingAnimation.duration = 1
        shimmingAnimation.repeatCount = 1
        shimmingAnimation.fromValue = _generateLocations(delta: -1.0)
        shimmingAnimation.toValue = _generateLocations(delta: +1.0)
        shimmingAnimation.fillMode = .forwards
        
        let shimmingGroup = CAAnimationGroup()
        shimmingGroup.animations = [shimmingAnimation]
        shimmingGroup.duration = shimmingAnimation.duration + 0.5
        shimmingGroup.repeatCount = .greatestFiniteMagnitude
        shimmingGroup.isRemovedOnCompletion = false
        gradient.add(shimmingGroup, forKey: "animateShimming")
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.duration = 0.25
        opacityAnimation.fromValue = (layer.presentation() ?? layer).opacity
        opacityAnimation.toValue = 1.0
        opacityAnimation.fillMode = .forwards
        opacityAnimation.isRemovedOnCompletion = false
        layer.add(opacityAnimation, forKey: "opacityAnimation")
    }
    
    func jv_stopShimming() {
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.duration = 0.25
        opacityAnimation.fromValue = (layer.presentation() ?? layer).opacity
        opacityAnimation.toValue = 0
        opacityAnimation.fillMode = .forwards
        opacityAnimation.isRemovedOnCompletion = false
        layer.add(opacityAnimation, forKey: "opacityAnimation")
    }
    
    func jv_addSubviews(children: UIView...) {
        children.forEach({ addSubview($0) })
    }

}
