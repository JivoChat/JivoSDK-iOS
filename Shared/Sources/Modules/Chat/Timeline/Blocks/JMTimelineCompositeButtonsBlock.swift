//
//  JMTimelineCompositeButtonsBlock.swift
//  JMTimeline
//
//  Created by Stan Potemkin on 06.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import TypedTextAttributes
import JMMarkdownKit
import JMTimelineKit

enum JMTimelineCompositeButtonsBehavior {
    case horizontal
    case vertical
}

struct JMTimelineCompositeButtonsStyle: JMTimelineStyle {
    let backgroundColor: UIColor
    let borderColor: UIColor
    let captionColor: UIColor
    let captionFont: UIFont
    let captionPadding: UIEdgeInsets
    let buttonGap: CGFloat
    let cornerRadius: CGFloat
    let shadowEnabled: Bool

    init(backgroundColor: UIColor,
         borderColor: UIColor,
         captionColor: UIColor,
         captionFont: UIFont,
         captionPadding: UIEdgeInsets,
         buttonGap: CGFloat,
         cornerRadius: CGFloat,
         shadowEnabled: Bool) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.captionColor = captionColor
        self.captionFont = captionFont
        self.captionPadding = captionPadding
        self.buttonGap = buttonGap
        self.cornerRadius = cornerRadius
        self.shadowEnabled = shadowEnabled
    }
}

final class JMTimelineCompositeButtonsBlock: UIView, JMTimelineBlockCallable {
    private let behavior: JMTimelineCompositeButtonsBehavior
    
    var tapHandler: ((Int) -> Void)?
    
    private var style: JMTimelineCompositeButtonsStyle?
    private var buttons = [UIButton]()
    private var captionPadding = UIEdgeInsets.zero
    private var buttonGap = CGFloat.zero
    private var shadowDistance = CGFloat.zero

    init(behavior: JMTimelineCompositeButtonsBehavior) {
        self.behavior = behavior
        
        super.init(frame: .zero)
        
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func link(provider: JMTimelineProvider, interactor: JMTimelineInteractor) {
    }
    
    func configure(captions: [String], tappable: Bool, style: JMTimelineCompositeButtonsStyle) {
        self.style = style
        
        captionPadding = style.captionPadding
        buttonGap = style.buttonGap
        
        if style.shadowEnabled {
            layer.shadowColor = JVDesign.colors.resolve(usage: .primaryForeground).cgColor
            layer.shadowOffset = CGSize(width: 0, height: 10)
            layer.shadowRadius = 6
            layer.shadowOpacity = 0.075
            shadowDistance = layer.shadowOffset.height + layer.shadowRadius
        }
        else {
            layer.shadowColor = nil
            layer.shadowRadius = 0
            layer.shadowOpacity = 0
            layer.shadowOffset = .zero
            shadowDistance = 0
        }
        
        buttons.forEach { $0.removeFromSuperview() }
        buttons = captions.map { caption in
            let button = UIButton()
            button.setBackgroundImage(UIImage(jv_color: style.backgroundColor), for: .normal)
            button.setBackgroundImage(UIImage(jv_color: style.captionColor), for: .highlighted)
            button.setTitle(caption, for: .normal)
            button.setTitleColor(style.captionColor, for: .normal)
            button.setTitleColor(JVDesign.colors.resolve(usage: .white), for: .highlighted)
            button.titleLabel?.font = style.captionFont
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.titleEdgeInsets = style.captionPadding
            button.layer.borderWidth = 1
            button.layer.borderColor = style.borderColor.cgColor
            button.layer.cornerRadius = style.cornerRadius
            button.layer.masksToBounds = true
            button.isUserInteractionEnabled = tappable
            button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
            return button
        }
        buttons.forEach { addSubview($0) }
    }
    
    func updateDesign() {
        if let style = style {
            for button in buttons {
                button.setBackgroundImage(UIImage(jv_color: style.backgroundColor), for: .normal)
                button.setBackgroundImage(UIImage(jv_color: style.captionColor), for: .highlighted)
            }
        }
        
        if shadowDistance > 0 {
            layer.shadowColor = JVDesign.colors.resolve(usage: .primaryForeground).cgColor
        }
    }
    
    func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return true
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        let layout = getLayout(size: bounds.size)
        zip(buttons, layout.buttonFrames).forEach { $0.frame = $1 }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDesign()
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            behavior: behavior,
            buttons: buttons,
            captionPadding: captionPadding,
            buttonGap: buttonGap,
            shadowDistance: shadowDistance)
    }
    
    @objc private func handleButtonTap(_ button: UIButton) {
        guard let index = buttons.firstIndex(of: button) else { return }
        tapHandler?(index)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let behavior: JMTimelineCompositeButtonsBehavior
    let buttons: [UIButton]
    let captionPadding: UIEdgeInsets
    let buttonGap: CGFloat
    let shadowDistance: CGFloat

    var buttonFrames: [CGRect] {
        var rect = CGRect.zero
        return buttons.map { button in
            let size = normalize(
                buttonSize: button
                    .sizeThatFits(.zero)
                    .jv_extendedBy(insets: button.titleEdgeInsets)
            )
            
            defer {
                rect.origin.x = rect.maxX + buttonGap
            }
            
            if rect.minX + size.width <= bounds.width {
                rect.size = size
                return rect
            }
            else {
                rect.origin.x = 0
                rect.origin.y += rect.height + buttonGap
                rect.size.width = min(bounds.width, size.width)
                rect.size.height = size.height
                return rect
            }
        }
    }
    
    var totalSize: CGSize {
        let width = buttonFrames.map(\.maxX).max() ?? 0
        let height = buttonFrames.last?.maxY ?? 0
        return CGSize(width: width, height: height + shadowDistance * 1.5)
    }
    
    private func normalize(buttonSize size: CGSize) -> CGSize {
        switch behavior {
        case .horizontal: return size
        case .vertical: return CGSize(width: bounds.width, height: size.height)
        }
    }
}
