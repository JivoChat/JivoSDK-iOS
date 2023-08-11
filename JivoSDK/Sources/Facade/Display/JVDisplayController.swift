//
//  SdkDisplayController.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 04.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import UIKit

/**
 ``Jivo``.``Jivo/display`` namespace for SDK displaying
 */
@objc(JVDisplayController)
public final class JVDisplayController: NSObject {
    private let joint = SdkJoint(engine: SdkEngine.shared)

    /**
     Object that controls displaying lifecycle
     */
    @objc(delegate)
    public weak var delegate: JVDisplayDelegate? {
        didSet {
            _delegateHookDidSet()
        }
    }
    
    /**
     Determines whether SDK is currently in UI hierarchy
     */
    @objc(isOnscreen)
    public var isOnscreen: Bool {
        return _isOnscreen()
    }
    
    /**
     Sets the custom locale for use instead of system one
     
     > Note: May be helpful in case you implement your own logic
     for changing a language locally within your app
     */
    @objc(setLocale:)
    public func setLocale(_ locale: Locale?) {
        _setLocale(locale)
    }
    
    /**
     Sets your own extra items to display within menu
     
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
     Places SDK into navigation stack (animated)
     
     - Parameter navigationController:
     Your existing UINavigationController to push the JivoSDK into
     */
    @objc(pushInto:)
    public func push(into navigationController: UINavigationController) {
        _push(into: navigationController)
    }

    /**
     Cleans entire stack of the passed navigationController,
     and then places SDK into it (not animated)
     
     - Parameter navigationController:
     Your existing UINavigationController to push the JivoSDK into
     - Parameter closeButton:
     Close Button look that mostly fits your needs in this case
     */
    @objc(placeWithin:closeButton:)
    public func place(within navigationController: UINavigationController, closeButton: JVDisplayCloseButton) {
        _place(within: navigationController, closeButton: closeButton)
    }
    
    /**
     Displays SDK modally on screen, slides it up from bottom edge (animated)
     
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
