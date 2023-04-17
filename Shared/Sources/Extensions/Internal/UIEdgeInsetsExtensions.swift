//
//  UIEdgeInsetsExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 11/07/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIEdgeInsets {
    init(jv_by value: CGFloat) {
        self.init(top: value, left: value, bottom: value, right: value)
    }
    
    var horizontal: CGFloat {
        return left + right
    }
    
    var vertical: CGFloat {
        return top + bottom
    }

    var inverted: UIEdgeInsets {
        return UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
    }

    func adding(top: CGFloat) -> UIEdgeInsets {
        var insets = self
        insets.top += top
        return insets
    }
}
