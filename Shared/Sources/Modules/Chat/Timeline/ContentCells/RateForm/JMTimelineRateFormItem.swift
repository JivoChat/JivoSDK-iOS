//
//  JMTimelineRateFormItem.swift
//  JivoSDK
//
//  Created by Julia Popova on 26.09.2023.
//

import UIKit
import JMRepicKit
import JMTimelineKit

struct JMTimelineRateFormInfo: JMTimelineInfo {
    let accentColor: UIColor?
    let sizing: JMTimelineRateFormControl.Sizing
    let rateConfig: JMTimelineRateConfig
    let lastRate: Int?
    let lastComment: String?
    let rateFormPreSubmitTitle: String?
    let rateFormPostSubmitTitle: String?
    let rateFormCommentPlaceholder: String?
    let rateFormSubmitCaption: String?
    let interactiveID: String?
    let keyboardAnchorControl: KeyboardAnchorControl
    let provider: JVChatTimelineProvider
    let interactor: JVChatTimelineInteractor
}

struct JMTimelineRateFormStyle: JMTimelineStyle {
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

final class JMTimelineRateFormItem: JMTimelinePayloadItem<JMTimelineRateFormInfo> {
    override var interactiveID: String? {
        return payload.interactiveID
    }
}
