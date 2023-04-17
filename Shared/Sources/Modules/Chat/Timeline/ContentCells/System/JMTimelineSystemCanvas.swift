//
//  JMTimelineSystemCanvas.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import DTModelStorage
import JMRepicKit
import JMTimelineKit

final class JMTimelineSystemCanvas: JMTimelineCanvas {
    private let iconView = JMRepicView.standard()
    private let plainBlock = JMTimelineCompositePlainBlock()
    private var buttonControls = [JMTimelineSystemButton]()
    
    private var useIcon = false
    private var buttons = [JMTimelineSystemButtonMeta]()
    
    override init() {
        super.init()
        
        addSubview(iconView)
        addSubview(plainBlock)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure(item: JMTimelineItem) {
        super.configure(item: item)
        
        if let info = (item as? JMTimelineSystemItem)?.payload {
            if let icon = info.icon {
                useIcon = true
                iconView.configure(items: [icon])
            }
            else {
                useIcon = false
            }
            
            plainBlock.configure(
                content: info.text,
                style: info.style,
                provider: info.provider,
                interactor: info.interactor)
            
            self.buttons = info.buttons
            
            buttonControls.forEach { $0.removeFromSuperview() }
            buttonControls = info.buttons.map { [unowned self] button in
                let control = JMTimelineSystemButton()
                control.caption = button.title
                control.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
                self.addSubview(control)
                return control
            }
        }
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineSystemStyle.self)
//
//        plainBlock.apply(
//            style: JMTimelinePlainStyle(
//                textColor: style.messageTextColor,
//                identityColor: style.identityColor,
//                linkColor: style.linkColor,
//                font: style.messageFont,
//                boldFont: nil,
//                italicsFont: nil,
//                strikeFont: nil,
//                lineHeight: 17,
//                alignment: style.messageAlignment,
//                underlineStyle: nil,
//                parseMarkdown: false)
//        )
//
//        buttonControls.forEach {
//            $0.apply(
//                style: JMTimelineSystemButtonStyle(
//                    backgroundColor: style.buttonBackgroundColor,
//                    textColor: style.buttonTextColor,
//                    font: style.buttonFont,
//                    margins: style.buttonMargins,
//                    underlineStyle: style.buttonUnderlineStyle,
//                    cornerRadius: style.buttonCornerRadius
//                )
//            )
//        }
//    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        iconView.frame = layout.iconViewFrame
        plainBlock.frame = layout.plainBlockFrame
        zip(buttonControls, layout.buttonsFrames).forEach { $0.0.frame = $0.1 }
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            iconView: iconView,
            plainBlock: plainBlock,
            useIcon: useIcon,
            buttonControls: buttonControls
        )
    }
    
    @objc private func handleButtonTap(_ control: JMTimelineSystemButton) {
        guard
            let item = item as? JMTimelineSystemItem,
            let index = buttonControls.firstIndex(of: control)
        else {
            return
        }
        
        let buttonId = buttons[index].ID
        item.payload.interactor.systemButtonTap(buttonID: buttonId)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let iconView: JMRepicView
    let plainBlock: JMTimelineCompositePlainBlock
    let useIcon: Bool
    let buttonControls: [UIButton]
    
    private let sideY = CGFloat(5)
    private let sideX = CGFloat(20)
    private let iconSide = CGFloat(42)
    private let iconMargin = CGFloat(7)
    
    var iconViewFrame: CGRect {
        if useIcon {
            return CGRect(
                x: (bounds.width - iconSide) * 0.5,
                y: sideY,
                width: iconSide,
                height: iconSide
            )
        }
        else {
            return CGRect(
                x: (bounds.width - iconSide) * 0.5,
                y: 0,
                width: iconSide,
                height: 0
            )
        }
    }
    
    var plainBlockFrame: CGRect {
        let reducedSise = bounds.insetBy(dx: sideX, dy: sideY).size
        let size = plainBlock.jv_size(forWidth: reducedSise.width)
        
        return CGRect(
            x: (bounds.width - size.width) * 0.5,
            y: (useIcon ? iconViewFrame.maxY + iconMargin : sideY),
            width: size.width,
            height: size.height
        )
    }
    
    var buttonsFrames: [CGRect] {
        let topY = plainBlockFrame.maxY + 5
        
        if buttonControls.isEmpty {
            return []
        }
        else if let buttonControl = buttonControls.first, buttonControls.count == 1 {
            let size = buttonControl.sizeThatFits(.zero)
            let leftX = (bounds.width - size.width) * 0.5
            
            return [
                CGRect(x: leftX, y: topY, width: size.width, height: size.height)
            ]
        }
        else {
            let base = CGRect(
                x: 0,
                y: topY,
                width: bounds.width,
                height: 20
            )
            
            return base
                .insetBy(dx: sideX, dy: 0)
                .jv_divide(by: .vertical, number: buttonControls.count)
        }
    }
    
    var totalSize: CGSize {
        if buttonControls.isEmpty {
            let blockFrame = plainBlockFrame
            let height = blockFrame.maxY + sideY
            return CGSize(width: blockFrame.width, height: height)
        }
        else {
            let height = (buttonsFrames.last?.maxY ?? 0) + sideY
            return CGSize(width: bounds.width,  height: height)
        }
    }
}
