//
//  JMTimelineRateButton.swift
//  JivoSDK
//
//  Created by Julia Popova on 09.10.2023.
//

import Foundation

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
            setImage(UIImage(named: "star_active", in: Bundle(for: JVDesign.self), compatibleWith: nil), for: .selected)
            setImage(UIImage(named: "star_inactive", in: Bundle(for: JVDesign.self), compatibleWith: nil), for: .normal)
        case (.smile, 5):
            setImage(UIImage(named: "smile_rate_\(filenameIndex)_active", in: Bundle(for: JVDesign.self), compatibleWith: nil), for: .selected)
            setImage(UIImage(named: "smile_rate_\(filenameIndex)_inactive", in: Bundle(for: JVDesign.self), compatibleWith: nil), for: .normal)
        case (.smile, 3):
            setImage(UIImage(named: "smile_rate_\(2 * filenameIndex - 1)_active", in: Bundle(for: JVDesign.self), compatibleWith: nil), for: .selected)
            setImage(UIImage(named: "smile_rate_\(2 * filenameIndex - 1)_inactive", in: Bundle(for: JVDesign.self), compatibleWith: nil), for: .normal)
        case (.smile, 2), (.smile, _):
            setImage(UIImage(named: "thumbs_rate_\(filenameIndex)_active", in: Bundle(for: JVDesign.self), compatibleWith: nil), for: .selected)
            setImage(UIImage(named: "thumbs_rate_\(filenameIndex)_inactive", in: Bundle(for: JVDesign.self), compatibleWith: nil), for: .normal)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
