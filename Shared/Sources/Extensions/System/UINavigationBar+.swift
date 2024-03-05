//
//  UINavigationBarExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 08/12/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationBar {
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

extension UIBarButtonItem {
    static func jv_spinner() -> UIBarButtonItem {
        return UIBarButtonItem(customView: UIActivityIndicatorView(style: .jv_auto).jv_started())
    }
}
