//
//  UITraitCollectionExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 28/09/2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UITraitCollection {
    func hasAnotherStyle(than anotherTraits: UITraitCollection?) -> Bool {
        if #available(iOS 12.0, *) {
            return (userInterfaceStyle != anotherTraits?.userInterfaceStyle)
        }
        else {
            return false
        }
    }
    
    func hasAnotherWidth(than anotherTraits: UITraitCollection?) -> Bool {
        if #available(iOS 12.0, *) {
            return (horizontalSizeClass != anotherTraits?.horizontalSizeClass)
        }
        else {
            return false
        }
    }
}
