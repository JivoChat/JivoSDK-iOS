//
//  JVDesignColors.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 11.03.2023.
//

import Foundation
import UIKit

protocol JVIDesignColors {
    func resolve(_ color: JVDesignColor) -> UIColor
    func resolve(_ color: JVDesignColor, style: JVDesignColorBrightness) -> UIColor
    func resolve(hex: Int) -> UIColor
    func resolve(alias: JVDesignColorAlias) -> UIColor
    func resolve(usage: JVDesignColorUsage) -> UIColor
}

enum JVDesignColor {
    case native(UIColor)
    case hex(Int)
    case alias(JVDesignColorAlias)
    case usage(JVDesignColorUsage)
}

enum JVDesignColorBrightness {
    case light
    case dark
}

enum JVDesignColorAlias {
    case darkBackground
    case white
    case black
    case systemBlue
    case systemGreen
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
    case adaptiveGreenJivo
    case greenSber
    case skyBlue
    case brightBlue
    case blueVk
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

enum JVDesignColorUsage {
    // global
    case white
    case black
    case clear
    case accentGreen
    case accentBlue
    case accentGraphite
    // backgrounds
    case primaryBackground
    case secondaryBackground
    case tertiaryBackground
    case statusBarBackground
    case statusBarFailureBackground
    case navigatorBackground
    case statusHatBackground
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
    case onboardingBackground
    // labels
    case primaryLabel
    case secondaryLabel
    case tertiaryLabel
    case quaternaryLabel
    // fills
    case primaryFill
    case secondaryFill
    case tertiaryFill
    case quaternaryFill
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
    case unnoticeableForeground
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
    case actionButtonCloud
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
    case timelineSeparator
    case nonOpaqueSeparator
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
    case commentInput
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
    
    case waPreviewTimeBadgeBackground
    case waPreviewTimeBadgeForeground
    case waPreviewTemplateAgentBubble
    case waPreviewTemplateClientBubble
    case waPreviewMessageReadCheckmark
    case waPreviewBackground
    case waPreviewTemplateClientMessageTime
    case waPreviewTemplateAgentMessageTime
    case waPreviewTemplateButtonsSeparatorColor
    
    case waTemplateCellShadow
    
    case listBackground
    case separatorColor_b9b9bb
    
    case pickerTint
    
    case chatResolvedButton
}
