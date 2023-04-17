//
//  UIScrollViewExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 15/03/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

public extension UIScrollView {
    var jv_isActivelyInteracting: Bool {
        return (isTracking || isDragging || isDecelerating)
    }
    
    func jv_scrollToTop(duration: TimeInterval, force: Bool = false) {
        UIView.animate(
            withDuration: duration,
            animations: { [unowned self] in
                let contentHeight = self.contentSize.height
                let topOffset = self.contentInset.top
                
                if contentHeight + topOffset > self.bounds.height || force {
                    self.contentOffset.y = -topOffset
                }
            }
        )
    }
    
    func jv_scrollToBottom(duration: TimeInterval) {
        UIView.animate(
            withDuration: duration,
            animations: { [unowned self] in
                let contentHeight = self.contentSize.height
                let topOffset = self.contentInset.top
                
                if contentHeight + topOffset > self.bounds.height {
                    self.contentOffset.y = contentHeight - self.bounds.height
                }
            }
        )
    }
    
    func jv_scrollToActive(frame: CGRect) {
        let topActiveY = contentOffset.y + contentInset.top
        let bottomActiveY = contentOffset.y + bounds.height - contentInset.bottom
        
        if frame.minY >= topActiveY, frame.maxY <= bottomActiveY {
            return
        }
        
        let positionY = max(0, frame.maxY + contentInset.bottom - bounds.height)
        contentOffset.y = positionY
    }
    
    func jv_hideExtraSubviewsIfNeeded() {
        if #available(iOS 13.2, *) {
            return
        }
        else if #available(iOS 13.0, *) {
            // proceed below
        }
        else {
            return
        }
        
        let simpleViews = subviews.filter { $0.superclass == UIResponder.self }
        simpleViews.forEach { $0.backgroundColor = nil }
    }
}
