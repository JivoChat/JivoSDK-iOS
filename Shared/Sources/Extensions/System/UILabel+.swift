//
//  UILabelExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 16/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    var jv_hasText: Bool {
        if let text = text {
            return !text.isEmpty
        }
        else {
            return false
        }
    }
    
    func jv_calculateSize(forWidth width: CGFloat) -> CGSize {
        if jv_hasText {
            let bounds = CGRect(x: 0, y: 0, width: width, height: .infinity)
            return textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines).size
        }
        else {
            return CGSize(width: font.xHeight, height: font.lineHeight)
        }
    }
    
    func jv_calculateHeight(forWidth width: CGFloat) -> CGFloat {
        return jv_calculateSize(forWidth: width).height
    }
}
