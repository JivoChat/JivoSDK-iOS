//
//  UIBlurEffectExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 05.10.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIBlurEffect.Style {
    static var thin: UIBlurEffect.Style {
        if #available(iOS 13.0, *) {
            return systemUltraThinMaterial
        }
        else {
            return light
        }
    }
}
