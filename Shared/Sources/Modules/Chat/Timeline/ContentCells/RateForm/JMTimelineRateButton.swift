//
//  JMTimelineRateButton.swift
//  JivoSDK
//
//  Created by Julia Popova on 09.10.2023.
//

import Foundation
import UIKit

class JMTimelineRateButton: UIButton {
    let choice: Int
    
    init(mark: JMTimelineRateIcon, total: Int, choice: Int) {
        self.choice = choice
        
        super.init(frame: .zero)
        
        self.isUserInteractionEnabled = false
        self.isSelected = false
        
        let filenameIndex = choice + 1
        
        switch (mark, total) {
        case (.star, _):
            setImage(UIImage.jv_named("star_active"), for: .selected)
            setImage(UIImage.jv_named("star_inactive"), for: .normal)
        case (.smile, 5):
            setImage(UIImage.jv_named("smile_rate_\(filenameIndex)_active"), for: .selected)
            setImage(UIImage.jv_named("smile_rate_\(filenameIndex)_inactive"), for: .normal)
        case (.smile, 3):
            setImage(UIImage.jv_named("smile_rate_\(2 * filenameIndex - 1)_active"), for: .selected)
            setImage(UIImage.jv_named("smile_rate_\(2 * filenameIndex - 1)_inactive"), for: .normal)
        case (.smile, 2), (.smile, _):
            setImage(UIImage.jv_named("thumbs_rate_\(filenameIndex)_active"), for: .selected)
            setImage(UIImage.jv_named("thumbs_rate_\(filenameIndex)_inactive"), for: .normal)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
