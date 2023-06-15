//
//  UITextViewExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 14/08/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

fileprivate let calculateStorage = NSTextStorage()
fileprivate let calculateContainer = NSTextContainer()
fileprivate let calculateManager = NSLayoutManager()

extension UITextView {
    func jv_calculateSize(for width: CGFloat, numberOfLines: Int?, exclusionPaths: [UIBezierPath] = []) -> CGSize {
        calculateContainer.size = CGSize(width: width, height: .infinity)
        calculateContainer.exclusionPaths = exclusionPaths
        calculateContainer.lineBreakMode = textContainer.lineBreakMode
        calculateContainer.lineFragmentPadding = textContainer.lineFragmentPadding
        calculateContainer.maximumNumberOfLines = numberOfLines ?? textContainer.maximumNumberOfLines
        
        calculateStorage.setAttributedString(attributedText)
        
        let containerIndex = calculateManager.textContainers.endIndex
        calculateManager.addTextContainer(calculateContainer)
        defer { calculateManager.removeTextContainer(at: containerIndex) }
        
        calculateStorage.addLayoutManager(calculateManager)
        defer { calculateStorage.removeLayoutManager(calculateManager) }
        
        calculateManager.glyphRange(for: calculateContainer)
        
        let rect = calculateManager.usedRect(for: calculateContainer)
        return rect.size
    }
    
    func jv_calculateContentOffset(for maxHeight: CGFloat) -> CGFloat? {
        guard selectedRange.location == text.count else { return nil }
        guard let font = font else { return nil }
        
        if jv_height(forWidth: bounds.width) > maxHeight {
            let selfHeight = bounds.height
            let contentHeight = contentSize.height
            let offset = contentOffset.y
            
            if contentHeight - selfHeight - offset < font.lineHeight * 2 {
                return contentHeight - selfHeight
            }
        }
        
        return nil
    }
}
