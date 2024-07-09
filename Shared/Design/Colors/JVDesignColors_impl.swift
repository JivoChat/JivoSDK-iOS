//
//  JVDesignColors.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 11.03.2023.
//

import Foundation
import UIKit

final class JVDesignColors: JVDesignEnvironmental, JVIDesignColors {
    func resolve(_ color: JVDesignColor, style: JVDesignColorBrightness) -> UIColor {
        switch color {
        case .native(let value): return value
        case .hex(let hex): return obtainColor(byHex: hex)
        case .alias(let alias): return obtainColor(forStyle: style, withAlias: alias)
        case .usage(let usage): return obtainColor(forUsage: usage)
        }
    }
    
    func resolve(_ color: JVDesignColor) -> UIColor {
        return resolve(color, style: .light)
    }
    
    func resolve(hex: Int) -> UIColor {
        return resolve(.hex(hex))
    }
    
    func resolve(alias: JVDesignColorAlias) -> UIColor {
        return resolve(.alias(alias))
    }
    
    func resolve(usage: JVDesignColorUsage) -> UIColor {
        return resolve(.usage(usage))
    }
    
    private func obtainColor(byHex hex: Int) -> UIColor {
        return UIColor(jv_hex: hex)
    }
    
    private func obtainColor(forStyle style: JVDesignColorBrightness, withAlias alias: JVDesignColorAlias) -> UIColor {
        switch style {
        case .light: return f_colors[style]?[alias] ?? .black
        case .dark: return f_colors[style]?[alias] ?? .white
        }
    }
    
    private func obtainColor(forUsage usage: JVDesignColorUsage) -> UIColor {
        switch usage {
        // global
        case .white: return UIColor.white
        case .black: return UIColor.black
        case .clear: return UIColor.clear
        case .accentGreen: return dynamicColor(light: .alias(.accentGreen), dark: .alias(.accentGreen))
        case .accentBlue: return dynamicColor(light: .alias(.accentBlue), dark: .alias(.accentBlue))
        case .accentGraphite: return dynamicColor(light: .alias(.accentGraphite), dark: .alias(.accentGraphite))
        // backgrounds
        case .statusBarBackground: return dynamicColor(light: .alias(.silverRegular), dark: .hex(0x151515))
        case .statusBarFailureBackground: return dynamicColor(light: .alias(.orangeRed), dark: .alias(.orangeRed))
        case .navigatorBackground: return dynamicColor(light: .alias(.white), dark: .hex(0x222222))
        case .statusHatBackground: return dynamicColor(light: .alias(.greenLight), dark: .alias(.greenLight))
        case .primaryBackground: return dynamicColor(light: .alias(.white), dark: .alias(.black))
        case .secondaryBackground: return dynamicColor(light: .hex(0xF2F2F7), dark: .hex(0x202020))
        case .slightBackground: return dynamicColor(light: .alias(.seashell), dark: .hex(0x1B1A1A))
        case .highlightBackground: return dynamicColor(light: .hex(0xCDE6FF), dark: .hex(0x3D566F))
        case .groupingBackground: return dynamicColor(light: .alias(.white), dark: .hex(0x1C1C1E))
        case .contentBackground: return dynamicColor(light: .alias(.grayLight), dark: .hex(0x202020))
        case .badgeBackground: return dynamicColor(light: .hex(0x808080), dark: .hex(0x808080))
        case .coveringBackground: return dynamicColor(light: .alias(.unknown1), dark: .hex(0x101010))
        case .darkBackground: return dynamicColor(light: .hex(0x1C1B17), dark: .hex(0x1C1B17))
        case .oppositeBackground: return dynamicColor(light: .alias(.black), dark: .alias(.white))
        case .attentiveLightBackground: return dynamicColor(light: .hex(0xEF9937), dark: .hex(0xEF9937))
        case .attentiveDarkBackground: return dynamicColor(light: .alias(.tangerine), dark: .alias(.tangerine))
        case .flashingBackground: return resolve(usage: .warnTint).jv_withAlpha(0.2)
        case .chattingBackground: return dynamicColor(light: .hex(0xF7F9FC), dark: .hex(0x101010))
        case .placeholderBackground: return dynamicColor(light: .hex(0xF1F1F2), dark: .hex(0x202020))
        // shadows
        case .dimmingShadow: return dynamicColor(light: .native(UIColor.black.jv_withAlpha(0.56)), dark: .native(UIColor.white.jv_withAlpha(0.25)))
        case .lightDimmingShadow: return dynamicColor(light: .native(UIColor.black.jv_withAlpha(0.26)), dark: .native(UIColor.white.jv_withAlpha(0.1)))
        case .focusingShadow: return dynamicColor(light: .hex(0x404040), dark: .alias(.white))
        // foregrounds
        case .statusHatForeground: return dynamicColor(light: .alias(.white), dark: .alias(.black))
        case .statusBarFailureForeground: return dynamicColor(light: .alias(.white), dark: .alias(.white))
        case .primaryForeground: return dynamicColor(light: .alias(.black), dark: .alias(.white))
        case .secondaryForeground: return dynamicColor(light: .alias(.steel), dark: .alias(.steel))
        case .headingForeground: return dynamicColor(light: .alias(.brightBlue), dark: .hex(0x0080FF))
        case .highlightForeground: return dynamicColor(light: .alias(.brightBlue), dark: .native(.white))
        case .warningForeground: return dynamicColor(light: .alias(.orangeRed), dark: .alias(.orangeRed))
        case .identityDetectionForeground: return UIColor.jv_dynamicLink ?? dynamicColor(light: .native(.black), dark: .alias(.white))
        case .linkDetectionForeground: return dynamicColor(light: .alias(.brightBlue), dark: .alias(.brightBlue))
        case .overpaintForeground: return dynamicColor(light: .alias(.grayLight), dark: .alias(.grayLight))
        case .oppositeForeground: return dynamicColor(light: .alias(.white), dark: .alias(.black))
        case .disabledForeground: return dynamicColor(light: .native(.lightGray), dark: .native(.darkGray))
        case .placeholderForeground: return dynamicColor(light: .hex(0xE1E1E2), dark: .hex(0x404040))
        case .unnoticeableForeground: return dynamicColor(light: .native(.black.withAlphaComponent(0.015)), dark: .native(.white.withAlphaComponent(0.035)))
        // gradients
        case .informativeGradientTop: return dynamicColor(light: .hex(0x0C1A40), dark: .hex(0x202020))
        case .informativeGradientBottom: return dynamicColor(light: .hex(0x263959), dark: .hex(0x202020))
        // buttons
        case .primaryButtonBackground: return dynamicColor(light: .alias(.greenJivo), dark: .alias(.greenJivo))
        case .primaryButtonForeground: return dynamicColor(light: .alias(.white), dark: .hex(0xE0E0E0))
        case .secondaryButtonBackground: return dynamicColor(light: .alias(.brightBlue), dark: .alias(.brightBlue))
        case .secondaryButtonForeground: return dynamicColor(light: .alias(.white), dark: .hex(0xE0E0E0))
        case .adaptiveButtonBackground: return dynamicColor(light: .alias(.white), dark: .hex(0x272729))
        case .adaptiveButtonForeground: return dynamicColor(light: .hex(0x767676), dark: .alias(.white))
        case .adaptiveButtonBorder: return dynamicColor(light: .alias(.black), dark: .native(.clear))
        case .saturatedButtonBackground: return dynamicColor(light: .hex(0x304CFB), dark: .hex(0x304CFB))
        case .saturatedButtonForeground: return dynamicColor(light: .alias(.white), dark: .hex(0xE0E0E0))
        case .dimmedButtonBackground: return dynamicColor(light: .alias(.grayDark), dark: .hex(0x505050))
        case .dimmedButtonForeground: return dynamicColor(light: .alias(.steel), dark: .hex(0xE0E0E0))
        case .triggerPrimaryButtonBackground: return dynamicColor(light: .alias(.brightBlue), dark: .alias(.brightBlue))
        case .triggerPrimaryButtonForeground: return dynamicColor(light: .alias(.white), dark: .hex(0xE0E0E0))
        case .triggerSecondaryButtonBackground: return dynamicColor(light: .hex(0xE1E1E2), dark: .alias(.white))
        case .triggerSecondaryButtonForeground: return dynamicColor(light: .hex(0x191919), dark: .hex(0x191919))
        case .actionButtonBackground: return dynamicColor(light: .alias(.white), dark: .alias(.black))
        case .actionButtonCloud: return dynamicColor(light: .hex(0xE6F0FF), dark: .hex(0x46505F))
        case .actionActiveButtonForeground: return dynamicColor(light: .alias(.brightBlue), dark: .hex(0x0080FF))
        case .actionInactiveButtonForeground: return dynamicColor(light: .alias(.steel), dark: .alias(.steel))
        case .actionNeutralButtonForeground: return dynamicColor(light: .alias(.black), dark: .alias(.white))
        case .actionDangerButtonForeground: return dynamicColor(light: .alias(.orangeRed), dark: .hex(0xFF6B30))
        case .actionPressedButtonForeground: return dynamicColor(light: .alias(.black), dark: .alias(.white))
        case .actionDisabledButtonForeground: return dynamicColor(light: .alias(.steel), dark: .alias(.steel))
        case .destructiveBrightButtonBackground: return dynamicColor(light: .alias(.reddishPink), dark: .alias(.reddishPink))
        case .destructiveDimmedButtonBackground: return dynamicColor(light: .hex(0xFC4946), dark: .hex(0xDD0D35))
        case .destructiveButtonForeground: return dynamicColor(light: .alias(.white), dark: .alias(.white))
        case .dialpadButtonForeground: return dynamicColor(light: .alias(.brightBlue), dark: .alias(.brightBlue))
        // separators
        case .primarySeparator: return dynamicColor(light: .alias(.silverLight), dark: .alias(.silverLight))
        case .secondarySeparator: return dynamicColor(light: .alias(.silverRegular), dark: .alias(.silverRegular))
        case .darkSeparator: return dynamicColor(light: .hex(0xD1D1D6), dark: .hex(0x737476))
        // controls
        case .navigatorTint: return dynamicColor(light: .alias(.brightBlue), dark: .alias(.white))
        case .focusedTint: return dynamicColor(light: .alias(.greenJivo), dark: .alias(.greenJivo))
        case .toggleOnTint: return dynamicColor(light: .alias(.greenJivo), dark: .alias(.greenJivo))
        case .toggleOffTint: return dynamicColor(light: .alias(.grayLight), dark: .hex(0xA0A0A0))
        case .checkmarkOnBackground: return dynamicColor(light: .alias(.brightBlue), dark: .alias(.steel))
        case .checkmarkOffBackground: return dynamicColor(light: .alias(.grayDark), dark: .alias(.steel))
        case .attentiveTint: return dynamicColor(light: .alias(.orangeRed), dark: .alias(.orangeRed))
        case .performableTint: return dynamicColor(light: .hex(0x086BCD), dark: .hex(0x086BCD))
        case .performingTint: return dynamicColor(light: .alias(.greenJivo), dark: .alias(.greenJivo))
        case .performedTint: return dynamicColor(light: .alias(.brightBlue), dark: .alias(.white))
        case .accessoryTint: return dynamicColor(light: .alias(.steel), dark: .native(.gray))
        case .inactiveTint: return dynamicColor(light: .hex(0xD0D0D0), dark: .hex(0x404040))
        case .dialpadButtonTint: return dynamicColor(light: .alias(.brightBlue), dark: .alias(.brightBlue))
        case .onlineTint: return dynamicColor(light: .alias(.greenJivo), dark: .alias(.greenJivo))
        case .awayTint: return dynamicColor(light: .alias(.sunflowerYellow), dark: .alias(.sunflowerYellow))
        case .warnTint: return dynamicColor(light: .hex(0xFC4946), dark: .hex(0xFC4946))
        case .decorativeTint: return dynamicColor(light: .hex(0xEFEFF0), dark: .hex(0x1C1C1F))
        // indicators
        case .counterBackground: return dynamicColor(light: .alias(.brightBlue), dark: .alias(.brightBlue))
        case .counterForeground: return dynamicColor(light: .alias(.white), dark: .alias(.white))
        case .activityCall: return dynamicColor(light: .alias(.greenJivo), dark: .alias(.greenJivo))
        case .activityActiveTask: return dynamicColor(light: .alias(.greenJivo), dark: .alias(.greenJivo))
        case .activityFiredTask: return dynamicColor(light: .alias(.reddishPink), dark: .alias(.reddishPink))
        // elements
        case .clientBackground: return dynamicColor(light: .alias(.greenJivo), dark: .alias(.greenJivo))
        case .clientForeground: return dynamicColor(light: .alias(.white), dark: .alias(.white))
        case .clientLinkForeground: return dynamicColor(light: .alias(.white), dark: .alias(.white))
        case .clientIdentityForeground: return dynamicColor(light: .native(.white), dark: .alias(.white))
        case .clientTime: return dynamicColor(light: .alias(.white), dark: .alias(.white))
        case .clientCheckmark: return dynamicColor(light: .alias(.white), dark: .alias(.white))
        case .agentBackground: return dynamicColor(light: .alias(.grayRegular), dark: .hex(0x333333))
        case .agentForeground: return dynamicColor(light: .alias(.black), dark: .alias(.white))
        case .agentLinkForeground: return obtainColor(forUsage: .linkDetectionForeground)
        case .agentIdentityForeground: return obtainColor(forUsage: .linkDetectionForeground)
        case .agentTime: return dynamicColor(light: .alias(.steel), dark: .alias(.steel))
        case .botButtonBackground: return dynamicColor(light: .hex(0xC0D0E0), dark: .hex(0x505050))
        case .botButtonForeground: return dynamicColor(light: .hex(0x202020), dark: .hex(0xD0D0D0))
        case .commentInput: return dynamicColor(light: .hex(0xFEFAEB), dark: .hex(0x41403C))
        case .commentBackground: return dynamicColor(light: .hex(0xFEEAAC), dark: .hex(0x614800))
        case .callBorder: return dynamicColor(light: .alias(.grayDark), dark: .alias(.grayDark))
        case .failedBackground: return dynamicColor(light: .alias(.orangeRed), dark: .alias(.orangeRed))
        case .playingPassed: return dynamicColor(light: .alias(.unknown2), dark: .alias(.unknown2))
        case .playingAwaiting: return dynamicColor(light: .alias(.grayDark), dark: .alias(.grayDark))
        case .orderTint: return dynamicColor(light: .hex(0x8770DC), dark: .hex(0x8770DC))
        case .photoLoadingErrorStubBackground: return dynamicColor(light: .alias(.grayRegular), dark: .hex(0x333333))
        case .photoLoadingErrorDescription: return dynamicColor(light: .alias(.steel), dark: .alias(.steel))
        case .mediaPlaceholderBackground: return dynamicColor(light: .alias(.grayLight), dark: .alias(.grayLight))
        case .quoteMark: return dynamicColor(light: .alias(.grayDark), dark: .alias(.grayDark))
        // audioPlayer
        case .audioPlayerBackground:
            return dynamicColor(light: .hex(0xE9EAEF), dark: .hex(0x333333))
        case .audioPlayerButtonBackground:
            return dynamicColor(light: .hex(0xE9EAEF), dark: .native(UIColor(white: 1.0, alpha: 0.38)))
        case .audioPlayerDuration:
            return dynamicColor(light: .native(UIColor(jv_hex: 0x3C3C43, alpha: 0.6)), dark: .native(UIColor(white: 1.0, alpha: 0.74)))
        case .audioPlayerMaxTrack:
            return dynamicColor(light: .native(UIColor(jv_hex: 0x3C3C43, alpha: 0.18)), dark: .native(UIColor(white: 1.0, alpha: 0.22)))
        case .waveformColor:
            return dynamicColor(light: .native(UIColor(jv_hex: 0x3C3C43, alpha: 0.6)), dark: .native(UIColor(white: 1.0, alpha: 0.38)))
        case .audioPlayerMinTrack:
            return dynamicColor(light: .native(UIColor(jv_hex: 0x3C3C43, alpha: 0.6)), dark: .native(UIColor(white: 1.0, alpha: 0.38)))
        case .audioPlayerButtonTint:
            return dynamicColor(light: .native(UIColor(jv_hex: 0x3C3C43, alpha: 0.6)), dark: .hex(0x333333))
        case .audioPlayerButtonBorder:
            return dynamicColor(light: .native(UIColor(jv_hex: 0x3C3C43, alpha: 0.18)), dark: .native(UIColor.clear))
        case .listBackground:
            return dynamicColor(light: .native(UIColor(jv_hex: 0xF7F8FC, alpha: 1.0)), dark: .native(UIColor(jv_hex: 0x1C1C1E, alpha: 1.0)))
        case .separatorColor_b9b9bb:
            return dynamicColor(light: .native(UIColor(jv_hex: 0xB9B9BB, alpha: 1.0)), dark: .native(UIColor(jv_hex: 0x373739, alpha: 1.0)))
        case .pickerTint:
            return dynamicColor(light: .native(UIColor(jv_hex: 0x3C3C43, alpha: 0.18)), dark: .native(UIColor(jv_hex: 0xFFFFFF, alpha: 0.18)))
        case .waPreviewTimeBadgeForeground:
            // TODO: - Convert to jv_hex
            return dynamicColor(light: .native(UIColor(red: 0.24, green: 0.24, blue: 0.26, alpha: 1)), dark: .native(UIColor(red: 0.65, green: 0.66, blue: 0.66, alpha: 1)))
        case .waPreviewTimeBadgeBackground:
            // TODO: - Convert to jv_hex
            return dynamicColor(light: .native(UIColor(red: 0.87, green: 0.87, blue: 0.91, alpha: 1)), dark: .native(UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1)))
        case .waPreviewTemplateAgentBubble:
            return dynamicColor(light: .native(UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)), dark: .native(UIColor(red: 0.21, green: 0.21, blue: 0.22, alpha: 1)))
        case .waPreviewTemplateClientBubble:
            return dynamicColor(light: .native(UIColor(red: 0.86, green: 0.97, blue: 0.77, alpha: 1)), dark: .native(UIColor(red: 0.13, green: 0.32, blue: 0.27, alpha: 1)))
        case .waPreviewMessageReadCheckmark:
            return UIColor(red: 0.2, green: 0.59, blue: 0.98, alpha: 1)
        case .waPreviewTemplateClientMessageTime:
            return dynamicColor(
                light: .native(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.25)),
                dark: .native(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4))
            )
        case .waPreviewTemplateAgentMessageTime:
            return dynamicColor(
                light: .native(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4)),
                dark: .native(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25))
            )
        case .waPreviewTemplateButtonsSeparatorColor:
            return dynamicColor(
                light: .native(UIColor(red: 198/255, green: 203/255, blue: 209/255, alpha: 1)),
                dark: .native(UIColor(red: 84/255, green: 84/255, blue: 88/255, alpha: 0.65))
            )
        case .waPreviewBackground:
            return dynamicColor(light: .native(UIColor(jv_hex: 0xE6DDD5, alpha: 1.0)), dark: .native(UIColor(jv_hex: 0x131517, alpha: 1.0)))
        }
    }
    
    private func dynamicColor(light lightColor: JVDesignColor, dark darkColor: JVDesignColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traits in
                let style = traits.toDesignStyle
                let color: JVDesignColor = jv_convert(style) { value in
                    switch value {
                    case .light: return lightColor
                    case .dark: return darkColor
                    }
                }
                
                return self.resolve(color, style: style)
            }
        }
        else {
            return resolve(lightColor, style: .light)
        }
    }
}

fileprivate extension UITraitCollection {
    var toDesignStyle: JVDesignColorBrightness {
        if #available(iOS 12.0, *) {
            switch userInterfaceStyle {
            case .light: return .light
            case .dark: return .dark
            case .unspecified: return .light
            @unknown default: return .light
            }
        }
        else {
            return .light
        }
    }
}

fileprivate let f_colors: [JVDesignColorBrightness: [JVDesignColorAlias: UIColor]] = [
    .light: [
        .darkBackground: UIColor(jv_hex: 0x1C1B17),
        .white: UIColor.white,
        .black: UIColor.black,
        .systemBlue: UIColor.systemBlue,
        .systemGreen: UIColor.systemGreen,
        .accentGreen: UIColor(jv_hex: 0x12A730),
        .accentBlue: UIColor(jv_hex: 0x086BCD),
        .accentGraphite: UIColor(jv_hex: 0x445669),
        .background: UIColor(jv_hex: 0xF7F9FC),
        .stillBackground: UIColor(jv_hex: 0xF7F7F7),
        .silverLight: UIColor(jv_hex: 0xD1D1D6),
        .silverRegular: UIColor(jv_hex: 0xC7C7CC),
        .steel: UIColor(jv_hex: 0x8E8E93),
        .grayLight: UIColor(jv_hex: 0xEFEFF4),
        .grayRegular: UIColor(jv_hex: 0xE9EBF0),
        .grayDark: UIColor(jv_hex: 0xE5E5EA),
        .tangerine: UIColor(jv_hex: 0xFF9500),
        .sunflowerYellow: UIColor(jv_hex: 0xFFCC00),
        .reddishPink: UIColor(jv_hex: 0xFF2D55),
        .orangeRed: UIColor(jv_hex: 0xFF3B30),
        .greenLight: UIColor(jv_hex: 0x4CD964),
        .greenJivo: UIColor(jv_hex: 0x00BC31),
        .greenSber: UIColor(jv_hex: 0x21A038),
        .blueVk: UIColor(jv_hex: 0x0077FF),
        .skyBlue: UIColor(jv_hex: 0x5AC8FA),
        .brightBlue: UIColor(jv_hex: 0x007AFF),
        .darkPeriwinkle: UIColor(jv_hex: 0x5856D6),
        .seashell: UIColor(jv_hex: 0xF1F0F0),
        .alto: UIColor(jv_hex: 0xDEDEDE),
        .unknown1: UIColor(jv_hex: 0xB7B7BC),
        .unknown2: UIColor(jv_hex: 0x59595E),
        .unknown3: UIColor(jv_hex: 0x009627),
        .unknown4: UIColor(jv_hex: 0xFAFAFB),
        .unknown5: UIColor(jv_hex: 0xA4B4BC),
        .color_ff2f0e: UIColor(jv_hex: 0xFF2F0E),
        .color_00bc31: UIColor(jv_hex: 0x00BC31)
    ],
    .dark: [
        .white: UIColor.white,
        .black: UIColor.black,
        .systemBlue: UIColor.systemBlue,
        .accentGreen: UIColor(jv_hex: 0x12A730),
        .accentBlue: UIColor(jv_hex: 0x086BCD),
        .accentGraphite: UIColor(jv_hex: 0x445669),
        .orangeRed: UIColor(jv_hex: 0xFF3B30),
        .greenJivo: UIColor(jv_hex: 0x008A0B),
        .greenSber: UIColor(jv_hex: 0x21A038),
        .blueVk: UIColor(jv_hex: 0x0077FF),
        .sunflowerYellow: UIColor(jv_hex: 0xFFCC00),
        .silverRegular: UIColor(jv_hex: 0xC7C7CC),
        .grayDark: UIColor(jv_hex: 0xE5E5EA),
        .greenLight: UIColor(jv_hex: 0x4CD964),
        .reddishPink: UIColor(jv_hex: 0xFF2D55),
        .steel: UIColor(jv_hex: 0x8E8E93),
        .darkBackground: UIColor(jv_hex: 0x1C1B17),
        .background: UIColor(jv_hex: 0xF7F9FC),
        .stillBackground: UIColor(jv_hex: 0xF7F7F7),
        .silverLight: UIColor(jv_hex: 0xD1D1D6),
        .grayRegular: UIColor(jv_hex: 0xE9EBF0),
        .tangerine: UIColor(jv_hex: 0xFF9500),
        .skyBlue: UIColor(jv_hex: 0x5AC8FA),
        .brightBlue: UIColor(jv_hex: 0x307AFF),
        .darkPeriwinkle: UIColor(jv_hex: 0x5856D6),
        .unknown1: UIColor(jv_hex: 0xC7C7CC),
        .unknown2: UIColor(jv_hex: 0x59595E),
        .unknown3: UIColor(jv_hex: 0x009627),
        .unknown4: UIColor(jv_hex: 0xFAFAFB),
        .unknown5: UIColor(jv_hex: 0xA4B4BC),
        .color_ff2f0e: UIColor(jv_hex: 0xFF2F0E),
        .color_00bc31: UIColor(jv_hex: 0x00BC31)
    ]
]
