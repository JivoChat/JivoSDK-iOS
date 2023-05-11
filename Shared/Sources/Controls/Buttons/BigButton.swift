//
//  BigButton.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/10/2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation

import UIKit

enum BigButtonType {
    case primary
    case secondary
    case saturated
    case dimmed
}

enum BigButtonSizing {
    case large
    case medium
}

class BigButton: BaseButton {
    private let longPressDuration: TimeInterval?
    
    init(type: BigButtonType, sizing: BigButtonSizing, longPressDuration: TimeInterval? = nil) {
        self.bigButtonType = type
        self.sizing = sizing
        self.longPressDuration = longPressDuration
        
        super.init(
            config: generateConfig(
                type: type,
                sizing: sizing,
                accentColor: nil,
                longPressDuration: longPressDuration)
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    final var bigButtonType: BigButtonType {
        didSet {
            regenerateConfig()
        }
    }
    
    final var sizing: BigButtonSizing {
        didSet {
            regenerateConfig()
        }
    }
    
    final var accentColor: UIColor? {
        didSet {
            regenerateConfig()
        }
    }
    
    final var caption: String {
        get {
            return content?.text ?? String()
        }
        set {
            switch sizing {
            case .large:
                let font = obtainLargeFont(fontLimit: fontLimit)
                content = ButtonContent.plain(newValue, font, nil, nil)
            case .medium:
                let font = obtainMediumFont(fontLimit: fontLimit)
                content = ButtonContent.plain(newValue, font, nil, nil)
            }
        }
    }
    
    private func regenerateConfig() {
        config = generateConfig(
            type: bigButtonType,
            sizing: sizing,
            accentColor: accentColor,
            longPressDuration: longPressDuration)
    }
}

fileprivate func generateConfig(type: BigButtonType, sizing: BigButtonSizing, accentColor: UIColor?, longPressDuration: TimeInterval?) -> ButtonConfig {
    return ButtonConfig(
        enabled: true,
        padding: jv_with(sizing) { value in
            switch value {
            case .large:
                return UIEdgeInsets(top: 15, left: 10, bottom: 14, right: 10)
            case .medium:
                return UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
            }
        },
        regularFillColor: jv_with(type) { value in
            if let accentColor = accentColor {
                return accentColor
            }
            
            switch value {
            case .primary: return JVDesign.colors.resolve(usage: .primaryButtonBackground)
            case .secondary: return JVDesign.colors.resolve(usage: .secondaryButtonBackground)
            case .saturated: return JVDesign.colors.resolve(usage: .saturatedButtonBackground)
            case .dimmed: return JVDesign.colors.resolve(usage: .dimmedButtonBackground)
            }
        },
        regularTitleColor: jv_with(type) { value in
            switch value {
            case .primary: return JVDesign.colors.resolve(usage: .primaryButtonForeground)
            case .secondary: return JVDesign.colors.resolve(usage: .secondaryButtonForeground)
            case .saturated: return JVDesign.colors.resolve(usage: .saturatedButtonForeground)
            case .dimmed: return JVDesign.colors.resolve(usage: .dimmedButtonForeground)
            }
        },
        pressedFillColor: nil,
        pressedTitleColor: JVDesign.colors.resolve(usage: .secondaryForeground),
        disabledFillColor: jv_with(type) { value in
            switch value {
            case .primary: return JVDesign.colors.resolve(usage: .dimmedButtonBackground)
            case .secondary: return nil
            case .saturated: return nil
            case .dimmed: return nil
            }
        },
        disabledTitleColor: jv_with(type) { value in
            switch value {
            case .primary: return JVDesign.colors.resolve(usage: .dimmedButtonForeground)
            case .secondary: return nil
            case .saturated: return nil
            case .dimmed: return nil
            }
        },
        multiline: false,
        fontReducing: true,
        contentAlignment: .center,
        longPressDuration: longPressDuration,
        spinner: ButtonSpinner(
            style: .jv_auto,
            color: jv_with(type) { value in
                switch value {
                case .primary: return .white
                case .secondary: return .white
                case .saturated: return .white
                case .dimmed: return .gray
                }
            },
            position: .center
        ),
        decoration: ButtonDecoration(
            cornerRadius: JVDesign.layout.controlBigRadius,
            border: nil,
            shadow: nil,
            indicatesTouch: false
        )
    )
}

fileprivate func obtainLargeFont(fontLimit: Int?) -> UIFont {
    if let limit = fontLimit {
        return JVDesign.fonts.resolve(.medium(16...limit), scaling: .callout)
    }
    else {
        return JVDesign.fonts.resolve(.medium(16), scaling: .callout)
    }
}

fileprivate func obtainMediumFont(fontLimit: Int?) -> UIFont {
    if let limit = fontLimit {
        return JVDesign.fonts.resolve(.semibold(15...limit), scaling: .callout)
    }
    else {
        return JVDesign.fonts.resolve(.semibold(15), scaling: .callout)
    }
}
