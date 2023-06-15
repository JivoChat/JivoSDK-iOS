//
//  JMTimelineCompositeTaskBlock.swift
//  JMTimelineKit
//
//  Created by Stan Potemkin on 16.07.2021.
//

import Foundation
import UIKit
import JMScalableView
import JMRepicKit
import JMTimelineKit

struct JMTimelineCompositeTaskStyle: JMTimelineStyle {
    let briefLabelColor: UIColor
    let briefLabelFont: UIFont
    let agentNameColor: UIColor
    let agentNameFont: UIFont
    let dateColor: UIColor
    let dateFont: UIFont
    
    init(briefLabelColor: UIColor,
                briefLabelFont: UIFont,
                agentNameColor: UIColor,
                agentNameFont: UIFont,
                dateColor: UIColor,
                dateFont: UIFont) {
        self.briefLabelColor = briefLabelColor
        self.briefLabelFont = briefLabelFont
        self.agentNameColor = agentNameColor
        self.agentNameFont = agentNameFont
        self.dateColor = dateColor
        self.dateFont = dateFont
    }
}

final class JMTimelineCompositeTaskBlock: UIView, JMTimelineBlockCallable {
    private let iconView = JMScalableView()
    private let briefLabel = UILabel()
    private let agentRepic = JMRepicView(config: generateRepicConfig())
    private let agentNameLabel = UILabel()
    private let dateLabel = UILabel()

    private var url: URL?
    private var style: JMTimelineCompositeTaskStyle!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(iconView)
        
        briefLabel.numberOfLines = 0
        addSubview(briefLabel)
        
        addSubview(agentRepic)
        
        agentNameLabel.numberOfLines = 0
        addSubview(agentNameLabel)
        
        dateLabel.numberOfLines = 0
        addSubview(dateLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(icon: UIImage?, brief: String, agentRepicItem: JMRepicItem?, agentName: String, date: String) {
        iconView.image = icon
        
//        briefLabel.textColor = style.briefLabelColor
//        briefLabel.font = style.briefLabelFont
        briefLabel.attributedText = NSAttributedString(
            string: brief,
            attributes: [
                .font: briefLabel.font as Any,
                .paragraphStyle: { () -> NSParagraphStyle in
                    let briefStyle = NSMutableParagraphStyle()
                    briefStyle.minimumLineHeight = 22
                    return briefStyle
                }()
            ]
        )
        
        agentRepic.configure(item: agentRepicItem)
        
        agentNameLabel.text = agentName
//        agentNameLabel.textColor = style.agentNameColor
//        agentNameLabel.font = style.agentNameFont

        dateLabel.text = date
//        dateLabel.textColor = style.dateColor
//        dateLabel.font = style.dateFont
    }
    
    func updateDesign() {
    }
    
    func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return false
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        iconView.frame = layout.iconViewFrame
        briefLabel.frame = layout.briefLabelFrame
        agentRepic.frame = layout.agentRepicFrame
        agentNameLabel.frame = layout.agentNameFrame
        dateLabel.frame = layout.dateLabelFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            iconView: iconView,
            briefLabel: briefLabel,
            agentRepic: agentRepic,
            agentNameLabel: agentNameLabel,
            dateLabel: dateLabel
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let iconView: JMScalableView
    let briefLabel: UILabel
    let agentRepic: JMRepicView
    let agentNameLabel: UILabel
    let dateLabel: UILabel
    
    private let agentRepicSide = CGFloat(20)

    var iconViewFrame: CGRect {
        return CGRect(x: 0, y: 0, width: 40, height: 40)
    }
    
    var briefLabelFrame: CGRect {
        let leftX = contentLeftX
        let size = briefLabel.jv_size(forWidth: bounds.width - 8 - leftX)
        return CGRect(x: leftX, y: 0, width: size.width, height: size.height)
    }
    
    var agentRepicFrame: CGRect {
        let leftX = contentLeftX
        let topY = agentNameFrame.midY - agentRepicSide * 0.5
        return CGRect(x: leftX, y: topY, width: agentRepicSide, height: agentRepicSide)
    }
    
    var agentNameFrame: CGRect {
        let topY = briefLabelFrame.maxY + 10
        let leftX = iconViewFrame.maxX + 10 + agentRepicSide + 12
        let width = bounds.width - leftX
        let height = agentNameLabel.jv_calculateHeight(forWidth: width)
        return CGRect(x: leftX, y: topY, width: width, height: height)
    }
    
    var dateLabelFrame: CGRect {
        let topY = agentNameFrame.maxY + 10
        let leftX = contentLeftX
        let size = dateLabel.jv_size(forWidth: bounds.width - leftX)
        return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
    }

    var totalSize: CGSize {
        let height = dateLabelFrame.maxY
        return CGSize(width: bounds.width, height: height)
    }
    
    private var contentLeftX: CGFloat {
        return iconViewFrame.maxX + 12
    }
}

fileprivate func generateRepicConfig() -> JMRepicConfig {
    return JMRepicConfig(
        side: 20,
        borderWidth: 0,
        borderColor: .clear,
        itemConfig: JMRepicItemConfig(
            borderWidthProvider: { _ in 0 },
            borderColor: .clear
        ),
        layoutMap: [
            1: [
                JMRepicLayoutItem(position: CGPoint(x: 0, y: 0), radius: 1.0)
            ]
        ]
    )
}
