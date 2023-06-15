//
//  JMTimelineTimepointLabel.swift
//  JMTimeline
//
//  Created by Stan Potemkin on 21.07.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import UIKit

final class JMTimelineTimepointLabel: UILabel {
    var padding = UIEdgeInsets.zero
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let orig = super.sizeThatFits(size)
        let width = orig.width + padding.horizontal
        let height = orig.height + padding.vertical
        return CGSize(width: width, height: height)
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        guard
            let caption = text,
            let font = font
        else {
            return CGRect(x: padding.left, y: padding.top, width: 0, height: 0)
        }
        
        let rect = (caption as NSString).boundingRect(
            with: CGSize(
                width: bounds.width - padding.horizontal,
                height: .infinity),
            options: [.usesLineFragmentOrigin],
            attributes: [.font: font],
            context: nil)
        
        return CGRect(
            x: padding.left,
            y: padding.top,
            width: rect.width,
            height: rect.height)
    }
    
    override func drawText(in rect: CGRect) {
        let area = rect.inset(by: padding)
        super.drawText(in: area)
    }
}
