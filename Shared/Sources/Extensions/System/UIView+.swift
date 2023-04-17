//
//  UIViewExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 20/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    enum JVPinMode {
        case bottomFlexible
        case bottomCentered
    }
    
    static func jv_ofHeight(_ height: CGFloat) -> UIView {
        let view = UIView()
        view.frame.size.height = height
        return view
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
}
