//
// Created by Stan Potemkin on 09/08/2018.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMRepicKit
import JMTimelineKit

struct JMTimelineSystemButtonMeta: Equatable {
    let ID: String
    let title: String
    
    init(ID: String,
                title: String) {
        self.ID = ID
        self.title = title
    }
}

struct JMTimelineSystemInfo: JMTimelineInfo {
    let icon: JMRepicItem?
    let text: String
    let style: JMTimelineCompositePlainStyle
    let interactiveID: String?
    let provider: JVChatTimelineProvider
    let interactor: JVChatTimelineInteractor
    let buttons: [JMTimelineSystemButtonMeta]
    
    init(icon: JMRepicItem?,
                text: String,
         style: JMTimelineCompositePlainStyle,
                interactiveID: String?,
                provider: JVChatTimelineProvider,
                interactor: JVChatTimelineInteractor,
                buttons: [JMTimelineSystemButtonMeta]) {
        self.icon = icon
        self.text = text
        self.style = style
        self.provider = provider
        self.interactor = interactor
        self.interactiveID = interactiveID
        self.buttons = buttons
    }
}

struct JMTimelineSystemStyle: JMTimelineStyle {
    let messageTextColor: UIColor
    let messageFont: UIFont
    let messageAlignment: NSTextAlignment
    let identityColor: UIColor
    let linkColor: UIColor
    let buttonBackgroundColor: UIColor
    let buttonTextColor: UIColor
    let buttonFont: UIFont
    let buttonMargins: UIEdgeInsets
    let buttonUnderlineStyle: NSUnderlineStyle
    let buttonCornerRadius: CGFloat
    
    init(messageTextColor: UIColor,
                messageFont: UIFont,
                messageAlignment: NSTextAlignment,
                identityColor: UIColor,
                linkColor: UIColor,
                buttonBackgroundColor: UIColor,
                buttonTextColor: UIColor,
                buttonFont: UIFont,
                buttonMargins: UIEdgeInsets,
                buttonUnderlineStyle: NSUnderlineStyle,
                buttonCornerRadius: CGFloat) {
        self.messageTextColor = messageTextColor
        self.messageFont = messageFont
        self.messageAlignment = messageAlignment
        self.identityColor = identityColor
        self.linkColor = linkColor
        self.buttonBackgroundColor = buttonBackgroundColor
        self.buttonTextColor = buttonTextColor
        self.buttonFont = buttonFont
        self.buttonMargins = buttonMargins
        self.buttonUnderlineStyle = buttonUnderlineStyle
        self.buttonCornerRadius = buttonCornerRadius
    }
}

final class JMTimelineSystemItem: JMTimelinePayloadItem<JMTimelineSystemInfo> {
    override var interactiveID: String? {
        return payload.interactiveID
    }
}
