//
//  JivoSDK_ChattingUI.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 02.04.2023.
//

import Foundation
import UIKit

@available(*, deprecated)
@objc(JivoSDKChattingUI)
public class JivoSDKChattingUI: NSObject, JVDisplayDelegate {
    private var config = JivoSDKChattingConfig() {
        didSet {
            Jivo.display.setLocale(config.locale)
        }
    }
    
    @objc(delegate)
    public var delegate: JivoSDKChattingUIDelegate? {
        didSet {
            Jivo.display.delegate = self
        }
    }
    
    @objc(isDisplaying)
    public var isDisplaying: Bool {
        return Jivo.display.isOnscreen
    }
    
    @objc(pushInto:)
    public func push(into navigationController: UINavigationController) {
        Jivo.display.push(into: navigationController)
    }
    
    @objc(pushInto:withConfig:)
    public func push(into navigationController: UINavigationController, config: JivoSDKChattingConfig) {
        self.config = config
        Jivo.display.push(into: navigationController)
    }
    
    @objc(placeWithin:)
    public func place(within navigationController: UINavigationController) {
        Jivo.display.place(within: navigationController, closeButton: .dismiss)
    }
    
    @objc(placeWithin:closeButton:)
    public func place(within navigationController: UINavigationController, closeButton: JivoSDKChattingCloseButton) {
        Jivo.display.place(within: navigationController, closeButton: closeButton.toNewAPI())
    }
    
    @objc(placeWithin:withConfig:)
    public func place(within navigationController: UINavigationController, config: JivoSDKChattingConfig) {
        self.config = config
        Jivo.display.place(within: navigationController, closeButton: .dismiss)
    }
    
    @objc(placeWithin:closeButton:withConfig:)
    public func place(within navigationController: UINavigationController, closeButton: JivoSDKChattingCloseButton, config: JivoSDKChattingConfig) {
        self.config = config
        Jivo.display.place(within: navigationController, closeButton: closeButton.toNewAPI())
    }
    
    @objc(presentOver:)
    public func present(over viewController: UIViewController) {
        Jivo.display.present(over: viewController)
    }
    
    @objc(presentOver:withConfig:)
    public func present(over viewController: UIViewController, config: JivoSDKChattingConfig) {
        self.config = config
        Jivo.display.present(over: viewController)
    }
    
    public func jivoDisplay(asksToAppear sdk: Jivo) {
        delegate?.jivo?(didRequestShowing: .shared)
    }
    
    public func jivoDisplay(willAppear sdk: Jivo) {
        delegate?.jivo?(willAppear: .shared)
    }
    
    public func jivoDisplay(didDisappear sdk: Jivo) {
        delegate?.jivo?(didDisappear: .shared)
    }
    
    public func jivoDisplay(defineText sdk: Jivo, forElement element: JVDisplayElement) -> String? {
        switch element {
        case .headerTitle:
            return config.titlePlaceholder
        case .headerSubtitle:
            return config.subtitleCaption
        case .replyPlaceholder:
            return config.inputPlaceholder
        case .replyPrefill:
            return config.inputPrefill
        case .messageHello:
            return config.activeMessage
        case .messageOffline:
            return config.offlineMessage
        default:
            return nil
        }
    }
    
    public func jivoDisplay(defineColor sdk: Jivo, forElement element: JVDisplayElement) -> UIColor? {
        switch element {
        case .headerTitle:
            return config.titleColor
        case .headerSubtitle:
            return config.subtitleColor
        case .outgoingElements:
            return config.outgoingColor
        default:
            return nil
        }
    }
    
    public func jivoDisplay(defineImage sdk: Jivo, forElement element: JVDisplayElement) -> UIImage? {
        switch element {
        case .headerIcon:
            switch config.icon {
            case nil:
                return nil
            case .default:
                return nil
            case .custom(let image):
                return image
            case .hidden:
                return UIImage()
            }
        default:
            return nil
        }
    }
}

@available(*, deprecated)
@objc(JivoSDKChattingUIDelegate)
public protocol JivoSDKChattingUIDelegate {
    @objc(jivoDidRequestShowing:)
    optional func jivo(didRequestShowing sdk: JivoSDK)
    
    @objc(jivoWillAppear:)
    optional func jivo(willAppear sdk: JivoSDK)
    
    @objc(jivoDidDisappear:)
    optional func jivo(didDisappear sdk: JivoSDK)
}

@available(*, deprecated)
@objc(JivoSDKChattingCloseButton)
public enum JivoSDKChattingCloseButton: Int {
    case omit
    case back
    case dismiss
}

@available(*, deprecated)
public enum JivoSDKTitleBarIconStyle {
    case `default`
    case hidden
    case custom(UIImage)
}

@available(*, deprecated)
@objc(JivoSDKChattingPaletteAlias)
public enum JivoSDKChattingPaletteAlias: Int {
    public static let standard = JivoSDKChattingPaletteAlias.green
    case green
    case blue
    case graphite
}

@available(*, deprecated)
@objc(JivoSDKChattingConfig)
public class JivoSDKChattingConfig: NSObject {
    let locale: Locale?
    let icon: JivoSDKTitleBarIconStyle?
    let titleColor: UIColor?
    let subtitleColor: UIColor?
    let outgoingColor: UIColor?
    let titlePlaceholder: String?
    let subtitleCaption: String?
    let inputPlaceholder: String?
    let inputPrefill: String?
    let activeMessage: String?
    let offlineMessage: String?
    let outcomingPalette: JivoSDKChattingPaletteAlias

    // Swift only initializer
    
    public init(
        locale: Locale? = nil,
        icon: JivoSDKTitleBarIconStyle? = nil,
        titlePlaceholder: String? = nil,
        titleColor: UIColor? = nil,
        subtitleCaption: String? = nil,
        subtitleColor: UIColor? = nil,
        outgoingColor: UIColor? = nil,
        inputPlaceholder: String? = nil,
        inputPrefill: String? = nil,
        activeMessage: String? = nil,
        offlineMessage: String? = nil,
        outcomingPalette: JivoSDKChattingPaletteAlias = .standard
    ) {
        self.locale = locale
        self.icon = icon
        self.titlePlaceholder = titlePlaceholder
        self.titleColor = titleColor
        self.subtitleCaption = subtitleCaption
        self.subtitleColor = subtitleColor
        self.outgoingColor = outgoingColor
        self.inputPlaceholder = inputPlaceholder
        self.inputPrefill = inputPrefill
        self.activeMessage = activeMessage
        self.offlineMessage = offlineMessage
        self.outcomingPalette = outcomingPalette

        super.init()
    }
    
    // Objective-C only initializer
    
    @available(swift, obsoleted: 0.1, message: "This is Objective-C only initializer. Use init(locale:icon:titlePlaceholder:titleColor:subtitleCaption:subtitleColor:inputPlaceholder:activeMessage:offlineMessage:outcomingPalette:) for Swift instead.")
    @objc public init(
        locale: Locale? = nil,
        useDefaultIcon: Bool = true,
        customIcon: UIImage? = nil,
        titlePlaceholder: String? = nil,
        titleColor: UIColor? = nil,
        subtitleCaption: String? = nil,
        subtitleColor: UIColor? = nil,
        outgoingColor: UIColor? = nil,
        inputPlaceholder: String? = nil,
        inputPrefill: String? = nil,
        activeMessage: String? = nil,
        offlineMessage: String? = nil,
        outcomingPalette: JivoSDKChattingPaletteAlias = .standard
    ) {
        self.locale = locale
        self.icon = useDefaultIcon
            ? .default
            : customIcon.flatMap { .custom($0) } ?? .hidden
        self.titlePlaceholder = titlePlaceholder
        self.titleColor = titleColor
        self.subtitleCaption = subtitleCaption
        self.subtitleColor = subtitleColor
        self.outgoingColor = outgoingColor
        self.inputPlaceholder = inputPlaceholder
        self.inputPrefill = inputPrefill
        self.activeMessage = activeMessage
        self.offlineMessage = offlineMessage
        self.outcomingPalette = outcomingPalette

        super.init()
    }
}

fileprivate extension JivoSDKChattingCloseButton {
    func toNewAPI() -> JVDisplayCloseButton {
        switch self {
        case .omit:
            return .omit
        case .back:
            return .back
        case .dismiss:
            return .dismiss
        }
    }
}
