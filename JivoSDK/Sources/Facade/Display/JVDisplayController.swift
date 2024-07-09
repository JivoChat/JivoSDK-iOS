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
     Here you can customize captions and texts for some elements
     */
    @objc(defineText:forElement:)
    public func define(text: String?, forElement element: JVDisplayElement) {
        _define(text: text, forElement: element)
    }

    /**
     Here you can customize colors for some elements
     */
    @objc(defineColor:forElement:)
    public func define(color: UIColor?, forElement element: JVDisplayElement) {
        _define(color: color, forElement: element)
    }

    /**
     Here you can customize icons for some elements
     */
    @objc(defineImage:forElement:)
    public func define(image: UIImage?, forElement element: JVDisplayElement) {
        _define(image: image, forElement: element)
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
    @discardableResult
    public func push(into navigationController: UINavigationController) -> JVSessionHandle? {
        return _push(into: navigationController)
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
    @discardableResult
    public func place(within navigationController: UINavigationController, closeButton: JVDisplayCloseButton) -> JVSessionHandle? {
        return _place(within: navigationController, closeButton: closeButton)
    }
    
    /**
     Displays SDK modally on screen, slides it up from bottom edge (animated)
     
     - Parameter viewController:
     Your UIViewController on top of which the JivoSDK will be displayed
     */
    @objc(presentOver:)
    @discardableResult
    public func present(over viewController: UIViewController) -> JVSessionHandle? {
        return _present(over: viewController)
    }
    
    /**
     Closes SDK if it is currently in UI hierarchy
     
     - Parameter animated:
     Whether SDK should be closed with animation or not
     */
    @objc(closeAnimated:)
    public func close(animated: Bool) {
        _close(animated: animated)
    }
}

extension JVDisplayController {
    private func _delegateHookDidSet() {
    }
    
    private func _isOnscreen() -> Bool {
        return joint.isDisplaying
    }
    
    private func _setLocale(_ locale: Locale?) {
        journal(layer: .facade) {"FACADE[display] set @locale[\(String(describing: locale))]"}
        
        joint.modifyConfig { config in
            config.locale = locale
        }
    }
    
    private func _define(text: String?, forElement element: JVDisplayElement) {
        joint.modifyConfig { config in
            config.customizationTextMapping[element] = text
        }
    }

    private func _define(color: UIColor?, forElement element: JVDisplayElement) {
        joint.modifyConfig { config in
            config.customizationColorMapping[element] = color
        }
    }

    private func _define(image: UIImage?, forElement element: JVDisplayElement) {
        joint.modifyConfig { config in
            config.customizationImageMapping[element] = image
        }
    }
    
    private func _setExtraItems(menu: JVDisplayMenu, captions: [String], handler: @escaping (Int) -> Void) {
        journal(layer: .facade) {"FACADE[display] set extra items for @menu[\(menu)] with @captions[\(captions)]"}
        
        joint.modifyConfig { config in
            config.extraMenuItems[menu] = captions
            config.extraMenuHandlers[menu] = handler
        }
    }
    
    private func _push(into navigationController: UINavigationController, funcname: String = #function) -> JVSessionHandle? {
        journal(layer: .facade) {"FACADE[display] push into navigationController"}
        assert(Thread.isMainThread, "Please call on Main Thread")
        _ensureShowingOnExclusiveRun(funcname: funcname)
        
        guard !joint.isDisplaying else {
            return nil
        }
        
        return joint.push(
            into: navigationController,
            displayDelegate: delegate)
    }
    
    private func _place(within navigationController: UINavigationController, closeButton: JVDisplayCloseButton, funcname: String = #function) -> JVSessionHandle? {
        journal(layer: .facade) {"FACADE[display] place within navigationController @closeButton[\(closeButton)]"}
        assert(Thread.isMainThread, "Please call on Main Thread")
        _ensureShowingOnExclusiveRun(funcname: funcname)

        guard !joint.isDisplaying else {
            return nil
        }
        
        return joint.place(
            within: navigationController,
            closeButton: closeButton,
            displayDelegate: delegate)
    }
    
    private func _present(over viewController: UIViewController, funcname: String = #function) -> JVSessionHandle? {
        journal(layer: .facade) {"FACADE[display] present over viewController"}
        assert(Thread.isMainThread, "Please call on Main Thread")
        _ensureShowingOnExclusiveRun(funcname: funcname)

        guard !joint.isDisplaying else {
            return nil
        }
        
        return joint.present(
            over: viewController,
            displayDelegate: delegate)
    }
    
    private func _close(animated: Bool) {
        joint.close(animated: animated)
    }
    
    private func _ensureShowingOnExclusiveRun(funcname: String = #function) {
        if let depname = Thread.current.threadDictionary[JVSessionController.setupFuncKey] as? String {
            assertionFailure("""
            
            ----------------------
            | Please don't worry!
            |
            | This assertion anyway won't be fired outside of Xcode run,
            | because we use assertionFailure() instead of preconditionFailure()
            |
            | To avoid this assertion,
            | please don't call Jivo.display.\(funcname)
            | immediately after Jivo.session.\(depname)
            |
            | Instead, call Jivo.session.setup()
            | as soon as you have received your client's identity
            | during your app authorization logic
            |
            | And then, after a while, call Jivo.display.\(funcname),
            | when you're going to show our SDK onscreen
            ----------------------
            """)
        }
    }
}
