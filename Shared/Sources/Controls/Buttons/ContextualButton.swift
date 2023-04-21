//
//  ContextualButton.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 06.03.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

import UIKit
import TypedTextAttributes

enum ContextualButtonDecor {
    case positive
    case negativeBright
    case negativeDimmed
}

final class ContextualButton: BaseButton {
    private let decor: ContextualButtonDecor
    
    init(decor: ContextualButtonDecor) {
        self.decor = decor
        
        let fillColor: UIColor = jv_with(decor) { value in
            switch value {
            case .positive: return JVDesign.colors.resolve(usage: .primaryButtonBackground)
            case .negativeBright: return JVDesign.colors.resolve(usage: .destructiveBrightButtonBackground)
            case .negativeDimmed: return JVDesign.colors.resolve(usage: .destructiveDimmedButtonBackground)
            }
        }
        
        super.init(
            config: ButtonConfig(
                enabled: true,
                padding: UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10),
                regularFillColor: fillColor,
                regularTitleColor: JVDesign.colors.resolve(usage: .white),
                pressedFillColor: nil,
                pressedTitleColor: JVDesign.colors.resolve(usage: .white),
                disabledFillColor: fillColor.jv_withAlpha(0.5),
                disabledTitleColor: JVDesign.colors.resolve(usage: .white),
                multiline: false,
                fontReducing: true,
                contentAlignment: .center,
                longPressDuration: nil,
                spinner: ButtonSpinner(
                    style: .jv_auto,
                    color: .white,
                    position: .center
                ),
                decoration: ButtonDecoration(
                    cornerRadius: 6,
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
        return JVDesign.fonts.resolve(.bold(14), scaling: .subheadline)
    }
    
    private func obtainAttributes(font: UIFont) -> TextAttributes {
        return TextAttributes()
            .font(font)
            .foregroundColor(config.regularTitleColor)
    }
}
