//
//  CGSizeExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 17/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

public extension CGSize {
    static func jv_sizeThatCovers(sizes: [CGSize]) -> CGSize {
        var maxWidth = CGFloat(0)
        var maxHeight = CGFloat(0)
        
        sizes.forEach {
            maxWidth = max(maxWidth, $0.width)
            maxHeight = max(maxHeight, $0.height)
        }
        
        return CGSize(width: maxWidth, height: maxHeight)
    }
    
    func jv_extendedBy(insets: UIEdgeInsets) -> CGSize {
        return CGSize(
            width: insets.left + width + insets.right,
            height: insets.top + height + insets.bottom
        )
    }
    
    func jv_extendedBy(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) -> CGSize {
        return CGSize(
            width: left + width + right,
            height: top + height + bottom
        )
    }
}
