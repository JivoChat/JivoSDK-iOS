//
//  ActionButton.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/10/2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif
import UIKit
import TypedTextAttributes


struct ActionButtonStyle: OptionSet {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    
    static let passive = ActionButtonStyle(rawValue: 1 << 0)
    static let active = ActionButtonStyle(rawValue: 1 << 1)
    static let danger = ActionButtonStyle(rawValue: 1 << 2)
    static let underline = ActionButtonStyle(rawValue: 1 << 3)
}

enum ActionButtonSize {
    case regular
    case compact
    case smallest
}

enum ActionButtonLayout {
    case side
    case center
}

final class ActionButton: BaseButton {
    private let style: ActionButtonStyle
    private let size: ActionButtonSize
    private let weight: JVDesignFontWeight
    
    init(style: ActionButtonStyle,
         size: ActionButtonSize = .regular,
         layout: ActionButtonLayout = .center,
         weight: JVDesignFontWeight = .regular) {
        self.style = style
        self.size = size
        self.weight = weight
        
        super.init(
            config: ButtonConfig(
                enabled: true,
                padding: jv_with(size) { value in
                    switch value {
                    case .regular: return UIEdgeInsets(top: 13, left: 10, bottom: 13, right: 10)
                    case .compact: return UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
                    case .smallest: return UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
                    }
                },
                regularFillColor: nil,
                regularTitleColor: jv_with(style) {
                    switch true {
                    case $0.contains(.passive): return JVDesign.colors.resolve(usage: .actionInactiveButtonForeground)
                    case $0.contains(.active): return JVDesign.colors.resolve(usage: .actionActiveButtonForeground)
                    case $0.contains(.danger): return JVDesign.colors.resolve(usage: .actionDangerButtonForeground)
                    default: return UIColor.jv_auto
                    }
                },
                pressedFillColor: nil,
                pressedTitleColor: JVDesign.colors.resolve(usage: .actionPressedButtonForeground),
                disabledFillColor: nil,
                disabledTitleColor: JVDesign.colors.resolve(usage: .actionDisabledButtonForeground),
                multiline: false,
                fontReducing: true,
                contentAlignment: jv_with(layout) { value in
                    switch value {
                    case .center: return .center
                    case .side: return .left
                    }
                },
                longPressDuration: nil,
                spinner: ButtonSpinner(
                    style: .jv_auto,
                    position: jv_with(layout) { value in
                        switch value {
                        case .center: return .center
                        case .side: return .right
                        }
                    }
                ),
                decoration: ButtonDecoration(
                    cornerRadius: 0,
                    border: nil,
                    shadow: nil,
                    indicatesTouch: false
                )
            )
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    final var caption: String {
        get {
            return content?.text ?? String()
        }
        set {
            let font = obtainFont()
            let regularAttributes = obtainAttributes(font: font)
            let pressedAttributes = obtainAttributes(font: font)
            content = ButtonContent.plain(newValue, nil, regularAttributes, pressedAttributes)
        }
    }
    
    final var captionsForSizing: [String]? {
        didSet {
            let font = obtainFont()
            let regularAttributes = obtainAttributes(font: font)
            let pressedAttributes = obtainAttributes(font: font)
            contentsForSizing = captionsForSizing?.compactMap { ButtonContent.plain($0, nil, regularAttributes, pressedAttributes) }
        }
    }
    
    private func obtainFont() -> UIFont {
        switch size {
        case .regular:
            return obtainRegularFont(weight: weight, fontLimit: fontLimit)
        case .compact:
            return obtainCompactFont(weight: weight)
        case .smallest:
            return obtainSmallestFont(weight: weight)
        }
    }
    
    private func obtainAttributes(font: UIFont) -> TextAttributes {
        return TextAttributes()
            .font(font)
            .foregroundColor(config.regularTitleColor)
            .underlineStyle(style.contains(.underline) ? .single : [])
    }
}

fileprivate func obtainRegularFont(weight: JVDesignFontWeight, fontLimit: Int?) -> UIFont {
    if let limit = fontLimit {
        return JVDesign.fonts.resolve(.regular(17...limit), scaling: .callout)
    }
    else {
        return JVDesign.fonts.resolve(.regular(17), scaling: .callout)
    }
}

fileprivate func obtainCompactFont(weight: JVDesignFontWeight) -> UIFont {
    let meta = JVDesignFontMeta(weight: weight, sizing: 17)
    return JVDesign.fonts.resolve(meta, scaling: .subheadline)
}

fileprivate func obtainSmallestFont(weight: JVDesignFontWeight) -> UIFont {
    let meta = JVDesignFontMeta(weight: weight, sizing: 12)
    return JVDesign.fonts.resolve(meta, scaling: .subheadline)
}
