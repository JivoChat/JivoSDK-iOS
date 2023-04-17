//
//  JVDesignColors.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 11.03.2023.
//

import Foundation
import UIKit

public protocol JVIDesignColors {
    func resolve(_ color: JVDesignColor) -> UIColor
    func resolve(_ color: JVDesignColor, style: JVDesignColorBrightness) -> UIColor
    func resolve(hex: Int) -> UIColor
    func resolve(alias: JVDesignColorAlias) -> UIColor
    func resolve(usage: JVDesignColorUsage) -> UIColor
}

public enum JVDesignColor {
    case native(UIColor)
    case hex(Int)
    case alias(JVDesignColorAlias)
    case usage(JVDesignColorUsage)
}

public enum JVDesignColorBrightness {
    case light
    case dark
}

public enum JVDesignColorAlias {
    case darkBackground
    case white
    case black
    case accentGreen
    case accentBlue
    case accentGraphite
    case background
    case stillBackground
    case silverLight
    case silverRegular
    case steel
    case grayLight
    case grayRegular
    case grayDark
    case tangerine
    case sunflowerYellow
    case reddishPink
    case orangeRed
    case greenLight
    case greenJivo
    case skyBlue
    case brightBlue
    case darkPeriwinkle
    case seashell
    case alto
    case unknown1
    case unknown2
    case unknown3
    case unknown4
    case unknown5
    case color_ff2f0e
    case color_00bc31
}

public enum JVDesignColorUsage {
    // global
    case white
    case black
    case clear
    case accentGreen
    case accentBlue
    case accentGraphite
    // backgrounds
    case statusBarBackground
    case statusBarFailureBackground
    case navigatorBackground
    case statusHatBackground
    case primaryBackground
    case secondaryBackground
    case slightBackground
    case highlightBackground
    case groupingBackground
    case contentBackground
    case badgeBackground
    case coveringBackground
    case darkBackground
    case oppositeBackground
    case attentiveLightBackground
    case attentiveDarkBackground
    case flashingBackground
    case chattingBackground
    case placeholderBackground
    // shadow
    case dimmingShadow
    case lightDimmingShadow
    case focusingShadow
    // foregrounds
    case statusHatForeground
    case statusBarFailureForeground
    case primaryForeground
    case secondaryForeground
    case headingForeground
    case highlightForeground
    case warningForeground
    case identityDetectionForeground
    case linkDetectionForeground
    case overpaintForeground
    case oppositeForeground
    case disabledForeground
    case placeholderForeground
    // gradients
    case informativeGradientTop
    case informativeGradientBottom
    // buttons
    case primaryButtonBackground
    case primaryButtonForeground
    case secondaryButtonBackground
    case secondaryButtonForeground
    case adaptiveButtonBackground
    case adaptiveButtonForeground
    case adaptiveButtonBorder
    case saturatedButtonBackground
    case saturatedButtonForeground
    case dimmedButtonBackground
    case dimmedButtonForeground
    case triggerPrimaryButtonBackground
    case triggerPrimaryButtonForeground
    case triggerSecondaryButtonBackground
    case triggerSecondaryButtonForeground
    case actionButtonBackground
    case actionActiveButtonForeground
    case actionInactiveButtonForeground
    case actionNeutralButtonForeground
    case actionDangerButtonForeground
    case actionPressedButtonForeground
    case actionDisabledButtonForeground
    case destructiveBrightButtonBackground
    case destructiveDimmedButtonBackground
    case destructiveButtonForeground
    case dialpadButtonForeground
    // separators
    case primarySeparator
    case secondarySeparator
    case darkSeparator
    // controls
    case navigatorTint
    case focusedTint
    case toggleOnTint
    case toggleOffTint
    case checkmarkOnBackground
    case checkmarkOffBackground
    case attentiveTint
    case performableTint
    case performingTint
    case performedTint
    case accessoryTint
    case inactiveTint
    case dialpadButtonTint
    case onlineTint
    case awayTint
    case warnTint
    case decorativeTint
    // indicators
    case counterBackground
    case counterForeground
    case activityCall
    case activityActiveTask
    case activityFiredTask
    // elements
    case clientBackground
    case clientForeground
    case clientLinkForeground
    case clientIdentityForeground
    case clientTime
    case clientCheckmark
    case agentBackground
    case agentForeground
    case agentLinkForeground
    case agentIdentityForeground
    case agentTime
    case commentBackground
    case botButtonBackground
    case botButtonForeground
    case callBorder
    case failedBackground
    case playingPassed
    case playingAwaiting
    case orderTint
    case photoLoadingErrorStubBackground
    case photoLoadingErrorDescription
    case mediaPlaceholderBackground
    case quoteMark
    
    case audioPlayerBackground
    case audioPlayerButtonBackground
    case audioPlayerButtonTint
    case audioPlayerButtonBorder
    case audioPlayerDuration
    case audioPlayerMinTrack
    case audioPlayerMaxTrack
    
    case waveformColor
}
