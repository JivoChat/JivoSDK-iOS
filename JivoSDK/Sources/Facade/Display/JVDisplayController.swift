//
//  SdkDisplayController.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 04.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import UIKit

/**
 Responsible for everything related to the visual representation of the chat on the screen
 */
@objc(JVDisplayController)
public final class JVDisplayController: NSObject {
    private let joint = SdkJoint(engine: SdkEngine.shared)

    /**
     Sets a delegate to monitor the JivoSDK displaying lifecycle
     */
    @objc(delegate)
    public weak var delegate: JVDisplayDelegate? {
        didSet {
            _delegateHookDidSet()
        }
    }
    
    /**
     Checks whether the JivoSDK is currently in the view hierarchy
     */
    @objc(isOnscreen)
    public var isOnscreen: Bool {
        return _isOnscreen()
    }
    
    /**
     Sets the custom locale to be used instead of one provided by system
     
     > Note: May be helpful in case you implement your own logic
     for changing a language locally within your app
     */
    @objc(setLocale:)
    public func setLocale(_ locale: Locale?) {
        _setLocale(locale)
    }
    
    /**
     Sets the extra custom menu items
     in case you wish to provide some extra buttons or actions
     within JivoSDK screen
     
     - Parameter menu:
     Which menu you wish to attach your extra actions to
     - Parameter captions:
     Captions or titles of your extra actions
     - Parameter handler:
     Callback that would be called when user taps your custom menu item in specified menu
     */
    @objc(setExtraItemsForMenu:captions:handler:)
    public func setExtraItems(menu: JVDisplayMenu, captions: [String], handler: @escaping (Int) -> Void) {
        _setExtraItems(menu: menu, captions: captions, handler: handler)
    }
    
    /**
     Adds the JivoSDK into the navigation stack (animated)
     
     - Parameter navigationController:
     Your existing UINavigationController to push the JivoSDK into
     */
    @objc(pushInto:)
    public func push(into navigationController: UINavigationController) {
        _push(into: navigationController)
    }

    /**
     Removes the entire stack of the passed navigationController,
     and adds the JivoSDK into it (not animated)
     
     - Parameter navigationController:
     Your existing UINavigationController to push the JivoSDK into
     - Parameter closeButton:
     Design of Close Button that mostly fits your needs in this case
     */
    @objc(placeWithin:closeButton:)
    public func place(within navigationController: UINavigationController, closeButton: JVDisplayCloseButton) {
        _place(within: navigationController, closeButton: closeButton)
    }
    
    /**
     Displays the JivoSDK modally on the screen, from bottom edge (animated)
     
     - Parameter viewController:
     Your UIViewController on top of which the JivoSDK will be displayed
     */
    @objc(presentOver:)
    public func present(over viewController: UIViewController) {
        _present(over: viewController)
    }
}

extension JVDisplayController {
    private func _delegateHookDidSet() {
    }
    
    private func _isOnscreen() -> Bool {
        return joint.isDisplaying
    }
    
    private func _setLocale(_ locale: Locale?) {
        journal {"FRONT[display] set @locale[\(String(describing: locale))]"}
        
        joint.modifyConfig { config in
            config.locale = locale
        }
    }
    
    private func _setExtraItems(menu: JVDisplayMenu, captions: [String], handler: @escaping (Int) -> Void) {
        journal {"FRONT[display] set extra items for @menu[\(menu)] with @captions[\(captions)]"}
        
        joint.modifyConfig { config in
            config.extraMenuItems[menu] = captions
            config.extraMenuHandlers[menu] = handler
        }
    }
    
    private func _push(into navigationController: UINavigationController) {
        journal {"FRONT[display] push into navigationController"}
        
        joint.push(
            into: navigationController,
            displayDelegate: delegate)
    }
    
    private func _place(within navigationController: UINavigationController, closeButton: JVDisplayCloseButton) {
        journal {"FRONT[display] place within navigationController @closeButton[\(closeButton)]"}
        
        joint.place(
            within: navigationController,
            closeButton: closeButton,
            displayDelegate: delegate)
    }
    
    private func _present(over viewController: UIViewController) {
        journal {"FRONT[display] present over viewController"}
        
        joint.present(
            over: viewController,
            displayDelegate: delegate)
    }
}
