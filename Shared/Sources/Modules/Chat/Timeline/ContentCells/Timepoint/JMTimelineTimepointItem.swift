//
//  JMTimelineTimepointItem.swift
//  JMTimeline
//
//  Created by Stan Potemkin on 21.07.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMRepicKit
import JMTimelineKit

struct JMTimelineTimepointInfo: JMTimelineInfo {
    let caption: String
    
    init(caption: String) {
        self.caption = caption
    }
}

struct JMTimelineTimepointStyle: JMTimelineStyle {
    let margins: UIEdgeInsets
    let alignment: NSTextAlignment
    let font: UIFont
    let textColor: UIColor
    let padding: UIEdgeInsets
    let borderWidth: CGFloat
    let borderColor: UIColor
    let borderRadius: CGFloat?
    
    init(margins: UIEdgeInsets,
                alignment: NSTextAlignment,
                font: UIFont,
                textColor: UIColor,
                padding: UIEdgeInsets,
                borderWidth: CGFloat,
                borderColor: UIColor,
                borderRadius: CGFloat?) {
        self.margins = margins
        self.alignment = alignment
        self.font = font
        self.textColor = textColor
        self.padding = padding
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.borderRadius = borderRadius
    }
}

final class JMTimelineTimepointItem: JMTimelinePayloadItem<JMTimelineTimepointInfo> {
    override var groupingID: String? {
        return nil
    }
}
