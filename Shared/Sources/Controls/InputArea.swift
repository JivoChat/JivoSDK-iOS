//
//  InputTextArea.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 07.10.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
import UIKit

class InputTextArea: UITextView {
    private let height: CGFloat?
    
    init(height: CGFloat? = nil) {
        self.height = height
        
        super.init(frame: .zero, textContainer: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var canBecomeFirstResponder: Bool {
        return canBecomeFirstResponderWithinTree(fallbackValue: super.canBecomeFirstResponder)
    }
    
    func canBecomeFirstResponderWithinTree(fallbackValue: Bool) -> Bool {
        var pointer: UIView = self
        
        while (pointer.superview != nil) {
            guard let parentView = pointer.superview else { return fallbackValue }
            guard parentView.isUserInteractionEnabled else { return false }
            pointer = parentView
        }
        
        return fallbackValue
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if let height = height {
            let width = super.sizeThatFits(size).width
            return CGSize(width: width, height: height)
        }
        else {
            return super.sizeThatFits(size)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        if let height = height {
            let width = super.intrinsicContentSize.width
            return CGSize(width: width, height: height)
        }
        else {
            return super.intrinsicContentSize
        }
    }
}
