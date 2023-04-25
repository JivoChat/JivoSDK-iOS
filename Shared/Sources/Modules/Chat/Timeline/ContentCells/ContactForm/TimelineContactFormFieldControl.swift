//
//  TimelineContactFormFieldControl.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 15.01.2023.
//

import Foundation
import UIKit
import JivoFoundation


final class TimelineContactFormFieldControl: UITextField {
    init() {
        super.init(frame: .zero)
        
        font = obtainCaptionFont()
        rightView = UIImageView(image: UIImage(named: "checkmark_green", in: Bundle(for: JVDesign.self), compatibleWith: nil))
        
        injectDecorations()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func injectDecorations() {
        let bottomLine = UIView()
        bottomLine.backgroundColor = JVDesign.colors.resolve(usage: .secondarySeparator)
        bottomLine.frame = CGRect(x: 0, y: -1, width: 0, height: 1)
        bottomLine.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        bottomLine.isUserInteractionEnabled = false
        addSubview(bottomLine)
    }
}

fileprivate func obtainCaptionFont() -> UIFont {
    return JVDesign.fonts.resolve(.medium(17), scaling: .callout)
}
