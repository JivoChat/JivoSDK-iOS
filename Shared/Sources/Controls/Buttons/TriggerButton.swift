//
//  TriggerButton.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 05/10/2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
import UIKit

enum TriggerButtonStyle {
    case primary
    case secondary
}

final class TriggerButton: BaseButton {
    private let size: Int
    private let weight: JVDesignFontWeight
    
    init(style: TriggerButtonStyle, size: Int = 14, weight: JVDesignFontWeight) {
        self.style = style
        self.size = size
        self.weight = weight
        
        super.init(
            config: generateConfig(style: style)
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var style: TriggerButtonStyle {
        didSet { config = generateConfig(style: style) }
    }
    
    final var caption: String {
        get {
            return content?.text ?? String()
        }
        set {
            let font = obtainFont(weight: weight, fontBase: size, fontLimit: fontLimit)
            content = ButtonContent.plain(newValue, font, nil, nil)
        }
    }
}

fileprivate func generateConfig(style: TriggerButtonStyle) -> ButtonConfig {
    return ButtonConfig(
        enabled: true,
        padding: UIEdgeInsets(top: 7, left: 13, bottom: 7, right: 13),
        regularFillColor: jv_with(style) { value in
            switch value {
            case .primary: return JVDesign.colors.resolve(usage: .triggerPrimaryButtonBackground)
            case .secondary: return JVDesign.colors.resolve(usage: .triggerSecondaryButtonBackground)
            }
        },
        regularTitleColor: jv_with(style) { value in
            switch value {
            case .primary: return JVDesign.colors.resolve(usage: .triggerPrimaryButtonForeground)
            case .secondary: return JVDesign.colors.resolve(usage: .triggerSecondaryButtonForeground)
            }
        },
        pressedFillColor: nil,
        pressedTitleColor: nil,
        disabledFillColor: nil,
        disabledTitleColor: nil,
        multiline: false,
        fontReducing: true,
        contentAlignment: .center,
        longPressDuration: nil,
        spinner: ButtonSpinner(
            style: .jv_auto,
            color: .gray,
            position: .center
        ),
        decoration: ButtonDecoration(
            cornerRadius: nil,
            border: nil,
            shadow: nil,
            indicatesTouch: false
        )
    )
}

fileprivate func obtainFont(weight: JVDesignFontWeight, fontBase: Int, fontLimit: Int?) -> UIFont {
    if let  limit = fontLimit {
        let meta = JVDesignFontMeta(weight: weight, sizing: fontBase...limit)
        return JVDesign.fonts.resolve(meta, scaling: .subheadline)
    }
    else {
        let meta = JVDesignFontMeta(weight: weight, sizing: fontBase)
        return JVDesign.fonts.resolve(meta, scaling: .subheadline)
    }
}
