//
//  UIButton+Ext.swift
//  App
//
//  Created by Yulia Popova on 24.10.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    var jv_image: UIImage? {
        get {
            return image(for: .normal)
        }
        set {
            setImage(newValue, for: .normal)
        }
    }
    
    func jv_setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
        guard let color = color
        else {
            setBackgroundImage(nil, for: state)
            return
        }
        
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        UIGraphicsBeginImageContext(rect.size)
        color.setFill()
        UIRectFill(rect)
        
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setBackgroundImage(colorImage, for: state)
    }
}

extension UIButton: Deprecations {
    var jv_showsTouchWhenHighlighted: Bool {
        get { (self as Deprecations).showsTouchWhenHighlighted }
        set { (self as Deprecations).showsTouchWhenHighlighted = newValue }
    }

    var jv_adjustsImageWhenHighlighted: Bool {
        get { (self as Deprecations).adjustsImageWhenHighlighted }
        set { (self as Deprecations).adjustsImageWhenHighlighted = newValue }
    }
    
    var jv_adjustsImageWhenDisabled: Bool {
        get { (self as Deprecations).adjustsImageWhenDisabled }
        set { (self as Deprecations).adjustsImageWhenDisabled = newValue }
    }
    
    var jv_contentEdgeInsets: UIEdgeInsets {
        get { (self as Deprecations).contentEdgeInsets }
        set { (self as Deprecations).contentEdgeInsets = newValue }
    }
    
    var jv_titleEdgeInsets: UIEdgeInsets {
        get { (self as Deprecations).titleEdgeInsets }
        set { (self as Deprecations).titleEdgeInsets = newValue }
    }
    
    var jv_imageEdgeInsets: UIEdgeInsets {
        get { (self as Deprecations).imageEdgeInsets }
        set { (self as Deprecations).imageEdgeInsets = newValue }
    }
}

fileprivate protocol Deprecations: AnyObject {
    var showsTouchWhenHighlighted: Bool { get set }
    var adjustsImageWhenHighlighted: Bool { get set }
    var adjustsImageWhenDisabled: Bool { get set }
    var contentEdgeInsets: UIEdgeInsets { get set }
    var titleEdgeInsets: UIEdgeInsets { get set }
    var imageEdgeInsets: UIEdgeInsets { get set }
}
