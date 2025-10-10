//
//  UIView+Ext.swift
//  App
//
//  Created by Yulia Popova on 05.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func jv_addBorder(edges: UIRectEdge, color: UIColor, width: CGFloat) {
        let possibleEdges: [UIRectEdge] = [.left, .top, .right, .bottom]
        for edge in possibleEdges {
            guard edges.contains(edge)
            else {
                continue
            }
            
            let border = UIView()
            border.backgroundColor = color
            border.layer.zPosition = .infinity
            addSubview(border)

            switch edge {
            case .left:
                border.frame = CGRect(x: 0, y: 0, width: width, height: bounds.height)
                border.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
            case .top:
                border.frame = CGRect(x: 0, y: 0, width: bounds.width, height: width)
                border.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            case .right:
                border.frame = CGRect(x: bounds.width - width, y: 0, width: width, height: bounds.height)
                border.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
            case .bottom:
                border.frame = CGRect(x: 0, y: bounds.height - width, width: bounds.width, height: width)
                border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
            default:
                border.removeFromSuperview()
            }
        }
    }
    
    func jv_addShadow(
        shadowColor: CGColor = JVDesign.colors.resolve(usage: .dimmingShadow).cgColor,
        shadowOffset: CGSize = CGSize.zero,
        shadowOpacity: Float = 1.0,
        shadowRadius: CGFloat = 8.0
    ) {
        layer.shadowColor = shadowColor
        layer.shadowOffset = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
        layer.masksToBounds = false
        layer.cornerRadius = shadowRadius
    }
    
    var jv_isBlinking: Bool {
        get {
            if let _ = layer.animation(forKey: #function) {
                return true
            }
            else {
                return false
            }
        }
        set {
            if newValue {
                guard layer.animation(forKey: #function) == nil
                else {
                    return
                }
                
                let animation = CAKeyframeAnimation(keyPath: "opacity")
                animation.duration = 2.0
                animation.values = [1.0, 1.0, 0, 0, 1.0, 1.0]
                animation.keyTimes = [0, 0.3, 0.4, 0.6, 0.7, 1.0]
                animation.repeatCount = .infinity
                layer.add(animation, forKey: #function)
            }
            else {
                layer.removeAnimation(forKey: #function)
            }
        }
    }
    
    func jv_hideExtraSubviewsIfNeeded() {
        if #available(iOS 13.2, *) {
            return
        }
        
        if #available(iOS 13.0, *) {
            // proceed below
        }
        else {
            return
        }
        
        let simpleViews = subviews.filter { $0.superclass == UIResponder.self }
        simpleViews.forEach { $0.backgroundColor = nil }
    }
}
