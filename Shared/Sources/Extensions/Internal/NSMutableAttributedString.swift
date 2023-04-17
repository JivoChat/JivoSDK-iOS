//
//  NSMutableAttributedString.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 27/07/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    func insertIcon(_ icon: UIImage, for font: UIFont, offset: CGVector = .zero) {
        let attachment = NSTextAttachment()
        attachment.image = icon
        attachment.bounds = CGRect(
            x: offset.dx,
            y: font.descender + offset.dy,
            width: icon.size.width,
            height: icon.size.height
        )
        
        append(
            NSAttributedString(attachment: attachment)
        )
    }
}

func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString()
    result.append(lhs)
    result.append(rhs)
    return result
}
