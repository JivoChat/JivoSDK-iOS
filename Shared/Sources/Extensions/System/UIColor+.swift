//
//  UIColorExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    static var jv_auto: UIColor {
        if #available(iOS 13.0, *) {
            return label
        }
        else {
            return black
        }
    }
    
    static var jv_dynamicLink: UIColor? {
        if #available(iOS 13.0, *) {
            return link
        }
        else {
            return nil
        }
    }
    
    convenience init(jv_hex hex: Int, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let b = CGFloat((hex & 0x0000FF) >> 0) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    convenience init(jv_hex hex: String) {
        if let code = Int(hex, radix: 16) {
            self.init(jv_hex: code)
        }
        else {
            self.init(white: 0, alpha: 1.0)
        }
    }
    
    func jv_withAlpha(_ alpha: CGFloat) -> UIColor {
        return withAlphaComponent(alpha)
    }
    
    var jv_isLight: Bool {
        var r = CGFloat(0), g = CGFloat(0), b = CGFloat(0)
        getRed(&r, green: &g, blue: &b, alpha: nil)
        
        let brightness = (r * 299.0 + g * 587.0 + b * 114.0) / 1000.0
        return (brightness > 0.5)
    }
    
    var jv_resolveToLight: UIColor {
        if #available(iOS 13.0, *) {
            return resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        }
        else {
            return self
        }
    }
    
    var jv_resolveToDark: UIColor {
        if #available(iOS 13.0, *) {
            return resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        }
        else {
            return self
        }
    }
}
