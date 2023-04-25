//
//  JMTimelineCompositeCallRecordlessBlock.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JivoFoundation
import JMTimelineKit

enum JMTimelineCompositeCallRecordlessTarget {
    case phone(String)
    case online
}

struct JMTimelineCompositeCallRecordlessStyle: JMTimelineStyle {
    let phoneTextColor: UIColor
    let phoneFont: UIFont
    let phoneLinesLimit: Int
}

final class JMTimelineCompositeCallRecordlessBlock: JMTimelineBlock {
    private let phoneLabel = UILabel()
    
    override init() {
        super.init()
        
        phoneLabel.lineBreakMode = .byTruncatingTail
        addSubview(phoneLabel)
        
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handlePhoneTap))
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(target: JMTimelineCompositeCallRecordlessTarget) {
        switch target {
        case .phone(let phone):
            phoneLabel.text = phone
            phoneLabel.textColor = JVDesign.colors.resolve(usage: .linkDetectionForeground)
        case .online:
            phoneLabel.text = loc["Message.Call.ToWidget"]
            phoneLabel.textColor = JVDesign.colors.resolve(usage: .secondaryForeground)
        }
        
        phoneLabel.font = obtainPhoneFont()
        phoneLabel.numberOfLines = JVDesign.fonts.numberOfLines(standard: 1)
    }
    
//    override func apply(style: JMTimelineStyle) {
//        let style = style.convert(to: JMTimelineCompositeCallRecordlessStyle.self)
//
//    }
    
    override func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return false
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        phoneLabel.frame = layout.phoneLabelFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            phoneLabel: phoneLabel
        )
    }
    
    @objc private func handlePhoneTap() {
        guard let phone = phoneLabel.text, phone.starts(with: "+") else {
            return
        }
        
        interactor?.call(phone: phone)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let phoneLabel: UILabel
    
    var phoneLabelFrame: CGRect {
        let height = phoneLabel.jv_size(forWidth: bounds.width).height
        return CGRect(x: 5, y: 0, width: bounds.width, height: height)
    }
    
    var totalSize: CGSize {
        return CGSize(width: bounds.width, height: phoneLabelFrame.height + 5)
    }
}

fileprivate func obtainPhoneFont() -> UIFont {
    return JVDesign.fonts.resolve(.medium(12), scaling: .caption1)
}
