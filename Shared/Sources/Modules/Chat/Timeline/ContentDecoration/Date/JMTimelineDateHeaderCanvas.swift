//
//  JMTimelineDateHeaderCanvas.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JivoFoundation
import JMTimelineKit

struct JMTimelineDateHeaderStyle: JMTimelineStyle {
    let backgroundColor: UIColor
    let shadowColor: UIColor
    let foregroundColor: UIColor
    let foregroundFont: UIFont
    
    init(backgroundColor: UIColor,
                shadowColor: UIColor,
                foregroundColor: UIColor,
                foregroundFont: UIFont) {
        self.backgroundColor = backgroundColor
        self.shadowColor = shadowColor
        self.foregroundColor = foregroundColor
        self.foregroundFont = foregroundFont
    }
}

final class JMTimelineDateHeaderCanvas: JMTimelineCanvas {
    private let shadowLayer = CAShapeLayer()
    private let dateLabel = UILabel()
    
    override init() {
        super.init()
        
        shadowLayer.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground).cgColor
        shadowLayer.shadowColor = JVDesign.colors.resolve(usage: .focusingShadow).cgColor
        shadowLayer.shadowOpacity = 0.5
        shadowLayer.shadowRadius = 0.5
        shadowLayer.shadowOffset = CGSize(width: 0, height: 0.5)
        layer.insertSublayer(shadowLayer, at: 0)
        
        dateLabel.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
        dateLabel.textColor = JVDesign.colors.resolve(usage: .secondaryForeground)
        dateLabel.font = obtainDateFont()
        dateLabel.textAlignment = .center
        dateLabel.numberOfLines = 0
        dateLabel.layer.masksToBounds = true
        addSubview(dateLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure(item: JMTimelineItem) {
        super.configure(item: item)
        
        if let info = (item as? JMTimelineDateItem)?.payload {
            dateLabel.text = info.caption
        }
    }
    
    override func updateDesign() {
        super.updateDesign()
        shadowLayer.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground).cgColor
        shadowLayer.shadowColor = JVDesign.colors.resolve(usage: .focusingShadow).cgColor
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineDateHeaderStyle.self)
//
//        shadowLayer.backgroundColor = style.backgroundColor.cgColor
//        shadowLayer.shadowColor = style.shadowColor.cgColor
//        dateLabel.backgroundColor = style.backgroundColor
//        dateLabel.textColor = style.foregroundColor
//        dateLabel.font = style.foregroundFont
//    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        shadowLayer.frame = layout.shadowLayerFrame
        shadowLayer.cornerRadius = layout.shadowLayerCornerRadius
        dateLabel.frame = layout.dateLabelFrame
        dateLabel.layer.cornerRadius = layout.dataLabelCornerRadius
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDesign()
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            dateLabel: dateLabel
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let dateLabel: UILabel
    
    private let insets = UIEdgeInsets(top: 5, left: 20, bottom: 5, right: 20)
    
    var shadowLayerFrame: CGRect {
        return dateLabelFrame
    }
    
    var shadowLayerCornerRadius: CGFloat {
        return dataLabelCornerRadius
    }
    
    var dateLabelFrame: CGRect {
        let size = dateLabel.sizeThatFits(.zero).jv_extendedBy(insets: insets)
        let leftX = (bounds.width - size.width) * 0.5
        return CGRect(x: leftX, y: 0, width: size.width, height: size.height)
    }
    
    var dataLabelCornerRadius: CGFloat {
        return dateLabelFrame.height * 0.5
    }
    
    var totalSize: CGSize {
        return dateLabel.sizeThatFits(.zero).jv_extendedBy(insets: insets)
    }
}

fileprivate func obtainDateFont() -> UIFont {
    return JVDesign.fonts.resolve(.light(12), scaling: .caption1)
}
