//
// Created by Stan Potemkin on 09/08/2018.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMRepicKit
import JMTimelineKit

struct JMTimelineContactFormInfo: JMTimelineInfo {
    let fields: [TimelineContactFormField]
    let cache: ChatTimelineContactFormCache
    let sizing: TimelineContactFormControl.Sizing
    let accentColor: UIColor?
    let interactiveID: String?
    let keyboardAnchorControl: KeyboardAnchorControl
    let provider: JVChatTimelineProvider
    let interactor: JVChatTimelineInteractor
    
    init(fields: [TimelineContactFormField],
         cache: ChatTimelineContactFormCache,
         sizing: TimelineContactFormControl.Sizing,
         accentColor: UIColor?,
         interactiveID: String?,
         keyboardAnchorControl: KeyboardAnchorControl,
         provider: JVChatTimelineProvider,
         interactor: JVChatTimelineInteractor) {
        self.fields = fields
        self.cache = cache
        self.sizing = sizing
        self.accentColor = accentColor
        self.interactiveID = interactiveID
        self.keyboardAnchorControl = keyboardAnchorControl
        self.provider = provider
        self.interactor = interactor
    }
}

struct JMTimelineContactFormStyle: JMTimelineStyle {
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

final class JMTimelineContactFormItem: JMTimelinePayloadItem<JMTimelineContactFormInfo> {
    override var interactiveID: String? {
        return payload.interactiveID
    }
}
