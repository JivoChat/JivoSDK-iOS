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
}

final class JMTimelineContactFormItem: JMTimelinePayloadItem<JMTimelineContactFormInfo> {
    override var interactiveID: String? {
        return payload.interactiveID
    }
}
