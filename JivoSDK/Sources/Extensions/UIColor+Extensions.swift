//
//  UIColor+Extensions.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 07.07.2021.
//  Copyright © 2021 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    static var dynamicTitle: UIColor {
        if #available(iOS 13.0, *) {
            return label
        }
        else {
            return black
        }
    }
    
    static var dynamicSubtitle: UIColor {
        if #available(iOS 13.0, *) {
            return secondaryLabel
        }
        else {
            return darkGray
        }
    }
}
