//
//  StackViewChild.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 07.10.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import UIKit

class StackViewChild: UIView {
    private let captionLabel = UILabel()
    private let content: UIView
    
    init(caption: String?, content: UIView) {
        self.content = content
        
        super.init(frame: .zero)
        
        if let caption = caption {
            captionLabel.text = caption
            captionLabel.textColor = JVDesign.colors.resolve(usage: .secondaryForeground)
            captionLabel.font = JVDesign.fonts.resolve(.regular(13), scaling: .body)
            addSubview(captionLabel)
        }
        
        addSubview(content)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        captionLabel.frame = layout.captionLabelFrame
        content.frame = layout.contentFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            captionLabel: captionLabel,
            content: content)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let captionLabel: UILabel
    let content: UIView
    
    private let margins = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
    private let gap = CGFloat(5)
    
    var captionLabelFrame: CGRect {
        let height = hasCaption ? captionLabel.jv_height(forWidth: innerWidth) : 0
        return CGRect(x: margins.left, y: margins.top, width: innerWidth, height: height)
    }
    
    var contentFrame: CGRect {
        let height = content.jv_height(forWidth: innerWidth)
        
        if hasCaption {
            let topY = captionLabelFrame.maxY + gap
            return CGRect(x: margins.left, y: topY, width: innerWidth, height: height)
        }
        else {
            return CGRect(x: margins.left, y: margins.top, width: innerWidth, height: height)
        }
    }
    
    var totalSize: CGSize {
        let height = contentFrame.maxY + margins.bottom
        return CGSize(width: bounds.width, height: height)
    }
    
    private var innerWidth: CGFloat {
        return (bounds.width - margins.horizontal)
    }
    
    private var hasCaption: Bool {
        return !(captionLabel.text?.jv_valuable == nil)
    }
}
