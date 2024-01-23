//
//  ChatTimelineVisualConfig.swift
//  App
//
//  Created by Julia Popova on 27.12.2023.
//

import UIKit

struct ChatTimelineVisualConfig {
    let outcomingPalette: Palette
    let rateForm: RateForm
}

extension ChatTimelineVisualConfig {
    struct Palette {
        let backgroundColor: UIColor
        let foregroundColor: UIColor
        let buttonsTintColor: UIColor
    }
    
    struct RateForm {
        let preSubmitTitle: String
        let postSubmitTitle: String
        let commentPlaceholder: String
        let submitCaption: String
    }
}
