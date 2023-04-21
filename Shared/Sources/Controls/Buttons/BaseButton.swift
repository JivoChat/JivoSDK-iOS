//
//  BaseButton.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/10/2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
import UIKit
#if canImport(JivoFoundation)
import JivoFoundation
#endif
import TypedTextAttributes

enum ButtonContent {
    case plain(String, UIFont?, TextAttributes?, TextAttributes?)
    case rich(NSAttributedString)
    case media(UIImage?, String?, UIFont?)
    
    var text: String {
        switch self {
        case .plain(let string, _, _, _): return string
        case .rich(let string): return string.string
        case .media(_, let string, _): return string ?? String()
        }
    }
}

enum ButtonSpinnerPosition {
    case center
    case right
}

enum ButtonActivityMode {
    case replace
    case additive
}

struct ButtonSpinner {
    let style: UIActivityIndicatorView.Style
    let color: UIColor
    let position: ButtonSpinnerPosition
}

struct ButtonCorners {
    let radius: CGFloat?
    let clip: Bool
}

struct ButtonDecoration {
    struct Border {
        let color: UIColor
        let width: CGFloat
    }
    
    struct Shadow {
        let color: UIColor
        let radius: CGFloat
        let direction: CGVector
    }
    
    let cornerRadius: CGFloat?
    let border: Border?
    let shadow: Shadow?
    let indicatesTouch: Bool
}

struct ButtonConfig {
    let enabled: Bool
    let padding: UIEdgeInsets
    let regularFillColor: UIColor?
    let regularTitleColor: UIColor?
    let pressedFillColor: UIColor?
    let pressedTitleColor: UIColor?
    let disabledFillColor: UIColor?
    let disabledTitleColor: UIColor?
    let multiline: Bool
    let fontReducing: Bool
    let contentAlignment: UIControl.ContentHorizontalAlignment
    let longPressDuration: TimeInterval?
    let spinner: ButtonSpinner?
    let decoration: ButtonDecoration?
}

class BaseButton: UIButton {
    var touchDownHandler: (() -> Void)?
    var shortTapHandler: (() -> Void)?
    var longPressHandler: (() -> Void)?
    
    private let awaitingIndicator = UIActivityIndicatorView()
    private var longPressGesture: UILongPressGestureRecognizer?
    
    private var currentActivityMode: ButtonActivityMode?
    private var canDetectTap = false

    init(config: ButtonConfig) {
        self.config = config
        
        super.init(frame: .zero)
        
        awaitingIndicator.color = config.spinner?.color
        awaitingIndicator.isHidden = true
        awaitingIndicator.isUserInteractionEnabled = false
        addSubview(awaitingIndicator)
        
        addTarget(self, action: #selector(handleTouch), for: .touchDown)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        addGestureRecognizer(recognizer)
        longPressGesture = recognizer
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var config: ButtonConfig {
        didSet { apply() }
    }
    
    var content: ButtonContent? {
        didSet { apply() }
    }
    
    var fontLimit: Int? {
        didSet { apply() }
    }
    
    var contentsForSizing: [ButtonContent]?
    var autoActivity: ButtonActivityMode?
    
    final var isSpinning: Bool {
        guard !awaitingIndicator.isHidden else { return false }
        guard awaitingIndicator.isAnimating else { return false }
        return true
    }
    
    final func start(activity: ButtonActivityMode) {
        awaitingIndicator.startAnimating()
        awaitingIndicator.isHidden = false

        currentActivityMode = activity

        UIView.setAnimationsEnabled(false)
        adjustTitle()
        setNeedsLayout()
        layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
    }
    
    final func stop() {
        awaitingIndicator.stopAnimating()
        awaitingIndicator.isHidden = true
        
        currentActivityMode = nil
        
        UIView.setAnimationsEnabled(false)
        adjustTitle()
        setNeedsLayout()
        layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if let contentsForSizing = contentsForSizing {
            let duplicate = BaseButton(config: config)
            var maximalSize = CGSize.zero
            
            for contentForSizing in contentsForSizing {
                duplicate.content = contentForSizing
                maximalSize = max(maximalSize, duplicate.sizeThatFits(size))
            }
            
            return maximalSize
        }
        else {
            let contentSize = super.sizeThatFits(size)
            return contentSize.jv_extendedBy(insets: config.padding)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        awaitingIndicator.frame = layout.awaitingIndicatorFrame
        subviews.first?.layer.cornerRadius = layout.cornerRadius
        applyBorder()
    }
    
    override var intrinsicContentSize: CGSize {
        let contentSize = super.intrinsicContentSize
        return contentSize.jv_extendedBy(insets: config.padding)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasAnotherStyle(than: previousTraitCollection) {
            apply()
        }
    }

    override func setTitle(_ title: String?, for state: UIControl.State) {
        preconditionFailure("Use .caption instead")
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            awaitingIndicator: awaitingIndicator,
            config: config
        )
    }
    
    private func apply() {
        showsTouchWhenHighlighted = config.decoration?.indicatesTouch ?? false
        isEnabled = (isEnabled && config.enabled)
        
        if let _ = config.regularFillColor {
            setBackgroundImage(UIImage(jv_color: config.regularFillColor), for: .normal)
            setBackgroundImage(UIImage(jv_color: config.pressedFillColor), for: .highlighted)
            setBackgroundImage(UIImage(jv_color: config.disabledFillColor), for: .disabled)
        }
        else {
            setBackgroundImage(UIImage(jv_color: UIColor.clear), for: .normal)
            setBackgroundImage(UIImage(jv_color: UIColor.clear), for: .highlighted)
            setBackgroundImage(UIImage(jv_color: UIColor.clear), for: .disabled)
        }
        
        setTitleColor(config.regularTitleColor, for: .normal)
        setTitleColor(config.pressedTitleColor, for: .highlighted)
        setTitleColor(config.disabledTitleColor, for: .disabled)

        titleLabel?.adjustsFontSizeToFitWidth = config.fontReducing
        titleLabel?.numberOfLines = config.multiline ? 0 : 1
        
        contentHorizontalAlignment = config.contentAlignment
        adjustsImageWhenHighlighted = (config.pressedFillColor == nil)
        
        if let spinner = config.spinner {
            awaitingIndicator.style = spinner.style
            awaitingIndicator.color = spinner.color
        }
        
        applyBorder()
        applyShadow()
        adjustTitle()

        longPressGesture?.minimumPressDuration = config.longPressDuration ?? 1
    }
    
    private func applyBorder() {
        guard let border = config.decoration?.border else { return }
        guard let imageLayer = (subviews.first as? UIImageView)?.layer else { return }
        
        imageLayer.borderColor = border.color.cgColor
        imageLayer.borderWidth = border.width
        imageLayer.masksToBounds = true
    }
    
    private func applyShadow() {
        guard let shadow = config.decoration?.shadow else { return }
        
        layer.shadowColor = JVDesign.colors.resolve(usage: .primaryForeground).jv_withAlpha(0.07).cgColor
        layer.shadowRadius = shadow.radius
        layer.shadowOffset = CGSize(width: shadow.direction.dx, height: shadow.direction.dy)
        layer.shadowOpacity = 1.0
    }
    
    private func adjustTitle() {
        if currentActivityMode == .replace {
            super.setTitle(String(" "), for: .normal)
            super.setTitle(String(" "), for: .highlighted)
            super.setTitle(String(" "), for: .disabled)

            super.setAttributedTitle(nil, for: .normal)
            super.setAttributedTitle(nil, for: .highlighted)
            super.setAttributedTitle(nil, for: .disabled)

            super.setImage(nil, for: .normal)
        }
        else {
            switch content {
            case .none:
                break
                
            case .plain(let title, let font, nil, nil):
                super.setTitle(title, for: .normal)
                super.setTitle(title, for: .highlighted)
                super.setTitle(title, for: .disabled)

                super.setAttributedTitle(nil, for: .normal)
                super.setAttributedTitle(nil, for: .highlighted)
                super.setAttributedTitle(nil, for: .disabled)

                super.setImage(nil, for: .normal)
                
                titleLabel?.font = font
                
            case .plain(let title, _, let regularAttributes, let pressedAttributes):
                if let attributes = regularAttributes {
                    super.setAttributedTitle(
                        title.attributed(
                            attributes.foregroundColor(config.regularTitleColor)),
                        for: .normal)
                    
                    super.setAttributedTitle(
                        title.attributed(
                            attributes.foregroundColor(config.disabledTitleColor)),
                        for: .disabled)
                }
                
                if let attributes = pressedAttributes ?? regularAttributes {
                    super.setAttributedTitle(
                        title.attributed(
                            attributes.foregroundColor(config.pressedTitleColor)),
                        for: .highlighted)
                }
                
                super.setImage(nil, for: .normal)
                
            case .rich(let string):
                super.setAttributedTitle(string, for: .normal)
                super.setAttributedTitle(string, for: .highlighted)
                super.setAttributedTitle(string, for: .disabled)

                super.setImage(nil, for: .normal)

            case .media(let icon, let title, let font):
                super.setTitle(title, for: .normal)
                super.setTitle(title, for: .highlighted)
                super.setTitle(title, for: .disabled)

                super.setAttributedTitle(nil, for: .normal)
                super.setAttributedTitle(nil, for: .highlighted)
                super.setAttributedTitle(nil, for: .disabled)

                super.setImage(icon, for: .normal)
                
                titleLabel?.font = font
            }
        }
    }
    
    @objc private func handleTouch() {
        canDetectTap = true
        touchDownHandler?()
    }

    @objc private func handleTap() {
        guard canDetectTap else { return }
        shortTapHandler?()
        
        if let activity = autoActivity {
            start(activity: activity)
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        canDetectTap = false
        longPressHandler?()
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let awaitingIndicator: UIActivityIndicatorView
    let config: ButtonConfig
    
    var awaitingIndicatorFrame: CGRect {
        guard let position = config.spinner?.position else {
            return .zero
        }
        
        switch position {
        case .center:
            return bounds
            
        case .right:
            let size = awaitingIndicator.sizeThatFits(.zero)
            return CGRect(
                x: bounds.width - size.width,
                y: (bounds.height - size.height) * 0.5,
                width: size.width,
                height: size.height
            )
        }
    }
    
    var cornerRadius: CGFloat {
        guard let decoration = config.decoration else { return 0 }
        guard let radius = decoration.cornerRadius else { return bounds.height * 0.5 }
        return radius
    }
}
