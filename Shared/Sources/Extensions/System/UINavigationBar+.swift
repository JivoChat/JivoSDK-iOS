//
//  UINavigationBarExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 08/12/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

public extension UINavigationBar {
    func jv_setShadowEnabled(_ enabled: Bool) {
        if enabled {
            setBackgroundImage(nil, for: .default)
            shadowImage = nil
        }
        else {
//            let color = UIColor(white: 0.85, alpha: 1.0)
//            let image = UIImage(color: UIColor(white: 0.85, alpha: 1.0))
//            tintColor = color
//            barTintColor = color
//            setBackgroundImage(image, for: .default)
//            shadowImage = image
        }
    }
}

public extension UINavigationItem {
    var jv_largeDisplayMode: LargeTitleDisplayMode {
        get {
            if #available(iOS 11.0, *) {
                return largeTitleDisplayMode
            }
            else {
                return .never
            }
        }
        set {
            if #available(iOS 11.0, *) {
                largeTitleDisplayMode = newValue
            }
        }
    }
}
