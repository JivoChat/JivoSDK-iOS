//
//  JMTimelineSystemEventButton.swift
//  JMTimeline
//
//  Created by Stan Potemkin on 30/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMDesignKit
import TypedTextAttributes
import JMTimelineKit

struct JMTimelineSystemButtonStyle: JMTimelineStyle {
    let backgroundColor: UIColor
    let textColor: UIColor
    let font: UIFont
    let margins: UIEdgeInsets
    let underlineStyle: NSUnderlineStyle
    let cornerRadius: CGFloat
}

final class JMTimelineSystemButton: UIButton, JMTimelineStylable {
    var tapHandler: (() -> Void)?
    
    init() {
        super.init(frame: .zero)
        
        layer.cornerRadius = 0
        layer.masksToBounds = true

        setBackgroundImage(UIImage(jv_color: UIColor.clear), for: .normal)
        setBackgroundImage(UIImage(jv_color: UIColor.clear), for: .highlighted)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var caption: String? {
        didSet {
            update(title: caption)
        }
    }
    
    func updateDesign() {
    }
    
    private func update(title: String?) {
        guard let title = title else {
            super.setAttributedTitle(nil, for: .normal)
            return
        }
        
        super.setAttributedTitle(
            title.attributed(
                TextAttributes(minimumCapacity: 1)
                    .backgroundColor(UIColor.clear)
                    .foregroundColor(JVDesign.colors.resolve(usage: .actionActiveButtonForeground))
                    .font(obtainCaptionFont())
                    .underlineStyle([])
            ),
            for: .normal
        )
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let size = super.sizeThatFits(size)
        return calculateResultingSize(size)
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return calculateResultingSize(size)
    }
    
    override func setTitle(_ title: String?, for state: UIControl.State) {
        preconditionFailure("Use .caption instead")
    }
    
    private func calculateResultingSize(_ size: CGSize) -> CGSize {
        let margins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let extendedSize = size.jv_extendedBy(insets: margins)
        return CGSize(width: extendedSize.width + extendedSize.height, height: extendedSize.height)
    }
    
    @objc private func handleTap() {
        tapHandler?()
    }
}

fileprivate func obtainCaptionFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(14), scaling: .subheadline)
}
