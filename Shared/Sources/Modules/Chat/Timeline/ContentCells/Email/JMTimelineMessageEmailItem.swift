//
//  JMTimelineMessageEmailItem.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMMarkdownKit
import JMTimelineKit

struct JMTimelineMessageEmailInfo: JMTimelineInfo {
    let headers: [JMTimelineCompositePair]
    let message: String
    let style: JMTimelineCompositePlainStyle
    
    init(headers: [JMTimelineCompositePair],
                message: String,
                style: JMTimelineCompositePlainStyle) {
        self.headers = headers
        self.message = message
        self.style = style
    }
}

struct JMTimelineEmailStyle: JMTimelineStyle {
    let headerColor: UIColor
    let headerFont: UIFont
    let messageColor: UIColor
    let identityColor: UIColor
    let linkColor: UIColor
    let messageFont: UIFont
    
    init(headerColor: UIColor,
                headerFont: UIFont,
                messageColor: UIColor,
                identityColor: UIColor,
                linkColor: UIColor,
                messageFont: UIFont) {
        self.headerColor = headerColor
        self.headerFont = headerFont
        self.messageColor = messageColor
        self.identityColor = identityColor
        self.linkColor = linkColor
        self.messageFont = messageFont
    }
}

final class JMTimelineMessageEmailItem: JMTimelineMessageItem {
}
