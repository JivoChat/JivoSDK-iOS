//
//  PopupInformingContainer.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.07.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

import UIKit

final class PopupInformingContainer: UIView {
    var completionHandler: (() -> Void)?
    
    private let underlay = UIView()
    private weak var activeOverlay: UIView?
    
    init() {
        super.init(frame: .zero)
        
        underlay.alpha = 0
        underlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(underlay)
        
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func display(title: String?, icon: UIImage?, template: Bool, iconMode: UIView.ContentMode) {
        let duration: TimeInterval
        if let title = title {
            let numberOfWords = title.split(separator: " ").count
            let niceDuration = TimeInterval(numberOfWords) * TimeInterval(0.5)
            duration = min(7.5, max(2.0, niceDuration))
        }
        else {
            duration = 0.1
        }
        
        underlay.backgroundColor = JVDesign.colors.resolve(usage: .focusingShadow)
        
        let shadowOpacity: CGFloat
        let subview: UIView
        if title == nil, icon == nil {
            shadowOpacity = 0
            subview = UIView()
        }
        else {
            shadowOpacity = 0.5
            subview = PopupInformingIcon(title: title ?? String(), icon: icon, template: template, iconMode: iconMode)
        }
        
        subview.bounds.size = CGSize(width: bounds.width * 0.8, height: 0)
        subview.bounds.size = subview.jv_size(forWidth: subview.bounds.width)
        subview.alpha = 0
        subview.center = bounds.jv_center()
        addSubview(subview)
        
        layoutIfNeeded()
        
        if let overlay = activeOverlay {
            overlay.tag = 1
            overlay.layer.removeAllAnimations()
            
            CATransaction.flush()
            CATransaction.begin()
            CATransaction.setCompletionBlock(overlay.removeFromSuperview)
            
            if shadowOpacity == .zero {
                underlay.layer.removeAllAnimations()
                underlay.layer.add(outAnimations(duration: 0.2), forKey: nil)
            }
            
            overlay.layer.add(outAnimations(duration: 0.2), forKey: nil)
            
            CATransaction.commit()
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            if (subview.tag == 0) { subview.removeFromSuperview() }
            self.completionHandler?()
        }
        underlay.layer.add(backgroundAnimations(alpha: shadowOpacity, duration: duration), forKey: nil)
        subview.layer.add(allAnimations(duration: duration), forKey: nil)
        CATransaction.commit()
        
        activeOverlay = subview
    }
    
    func backgroundAnimations(alpha: CGFloat, duration: TimeInterval) -> CAAnimationGroup {
        let alphaAnimation = CAKeyframeAnimation(keyPath: "opacity")
        alphaAnimation.values = [0, alpha, alpha, 0]
        alphaAnimation.keyTimes = [0, 0.1, 0.95, 1.0]
        alphaAnimation.duration = duration
        
        let group = CAAnimationGroup()
        group.animations = [alphaAnimation]
        group.duration = duration
        return group
    }
    
    func allAnimations(duration: TimeInterval) -> CAAnimationGroup {
        let alphaAnimation = CAKeyframeAnimation(keyPath: "opacity")
        alphaAnimation.values = [0, 1.0, 1.0, 0]
        alphaAnimation.keyTimes = [0, 0.1, 0.95, 1.0]
        alphaAnimation.duration = duration
        
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform")
        scaleAnimation.values = [0.9, 1.1, 1.0, 1.0, 1.2].map { CATransform3DMakeScale($0, $0, 1.0) }
        scaleAnimation.keyTimes = [0, 0.05, 0.1, 0.95, 1.0]
        scaleAnimation.duration = duration
        
        let group = CAAnimationGroup()
        group.animations = [alphaAnimation, scaleAnimation]
        group.duration = duration
        return group
    }
    
    func outAnimations(duration: TimeInterval) -> CAAnimationGroup {
        let alphaAnimation = CAKeyframeAnimation(keyPath: "opacity")
        alphaAnimation.values = [1.0, 0]
        alphaAnimation.keyTimes = [0, 1.0]
        alphaAnimation.duration = duration
        
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform")
        scaleAnimation.values = [1.0, 1.2].map { CATransform3DMakeScale($0, $0, 1.0) }
        scaleAnimation.keyTimes = [0, 1.0]
        scaleAnimation.duration = duration
        
        let group = CAAnimationGroup()
        group.animations = [alphaAnimation, scaleAnimation]
        group.duration = duration
        return group
    }
}
