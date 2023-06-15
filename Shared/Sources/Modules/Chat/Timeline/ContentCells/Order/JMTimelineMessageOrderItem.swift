//
//  JMTimelineMessageOrderItem.swift
//  JMTimelineKit
//
//  Created by Stan Potemkin on 25.09.2020.
//

import Foundation
import JMRepicKit
import JMTimelineKit

struct JMTimelineMessageOrderInfo: JMTimelineInfo {
    let repic: JMRepicItem
    let repicTint: UIColor
    let subject: String
    let email: String?
    let phone: String?
    let text: String
    let button: String

    init(repic: JMRepicItem, repicTint: UIColor, subject: String, email: String?, phone: String?, text: String, button: String) {
        self.repic = repic
        self.repicTint = repicTint
        self.subject = subject
        self.email = email
        self.phone = phone
        self.text = text
        self.button = button
    }
}

struct JMTimelineOrderStyle: JMTimelineStyle {
    let headingIconBackground: UIColor
    let headingIconTint: UIColor
    let headingCaptionColor: UIColor
    let headingCaptionFont: UIFont
    let contactsColor: UIColor
    let contactsFont: UIFont
    let detailsColor: UIColor
    let detailsFont: UIFont
    let actionButton: JMTimelineCompositeButtonsStyle

    init(headingIconBackground: UIColor,
                headingIconTint: UIColor,
                headingCaptionColor: UIColor,
                headingCaptionFont: UIFont,
                contactsColor: UIColor,
                contactsFont: UIFont,
                detailsColor: UIColor,
                detailsFont: UIFont,
                actionButton: JMTimelineCompositeButtonsStyle) {
        self.headingIconBackground = headingIconBackground
        self.headingIconTint = headingIconTint
        self.headingCaptionColor = headingCaptionColor
        self.headingCaptionFont = headingCaptionFont
        self.contactsColor = contactsColor
        self.contactsFont = contactsFont
        self.detailsColor = detailsColor
        self.detailsFont = detailsFont
        self.actionButton = actionButton
    }
}

final class JMTimelineMessageOrderItem: JMTimelineMessageItem {
}
