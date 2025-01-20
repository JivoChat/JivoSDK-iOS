//
//  ChatTimelineMessageExtras.swift
//  App
//
//  Created by Stan Potemkin on 17.12.2024.
//

import Foundation
import JMTimelineKit

struct ChatTimelineMessageExtras {
    let caption: String?
    let reactions: [ChatTimelineMessageExtrasReaction]
    let actions: [ChatTimelineMessageExtrasAction]
}

struct ChatTimelineMessageExtrasReaction {
    let emoji: String
    let number: Int
    let participated: Bool
}

struct ChatTimelineMessageExtrasAction {
    let ID: String
    let icon: UIImage
}

struct ChatTimelineMessageExtrasReactionStyle: JMTimelineStyle {
    struct Element {
        let paddingCoef: CGFloat
        let fontReducer: CGFloat
        let pullingCoef: CGFloat
    }
    
    let height: CGFloat
    let baseFont: UIFont
    let regularBackgroundColor: UIColor
    let regularNumberColor: UIColor
    let selectedBackgroundColor: UIColor
    let selectedNumberColor: UIColor
    let sidePaddingCoef: CGFloat
    let emojiElement: Element
    let counterElement: Element
    let actionElement: Element
}
