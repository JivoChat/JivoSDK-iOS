//
//  SdkDisplayController.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 04.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import UIKit

#if canImport(SwiftUI)
import SwiftUI
#endif

@available(iOS 13.0, *)
public enum JVDisplayScreenPresentation {
    /**
     To present modally from bottom edge,  
     we recommend to use it alongwith .fullScreenCover(...) method
     */
    case modal
}

/**
 ``Jivo``.``Jivo/display`` namespace for SDK displaying
 */
@objc(JVDisplayController)
public final class JVDisplayController: NSObject {
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
    public func setLocale(_ locale: Locale?) {
        _setLocale(locale)
    }
    
    @objc(__setLocale:)
    public func __setLocale(_ identifier: String?) {
        if let identifier {
            _setLocale(Locale(identifier: identifier))
        }
        else {
            _setLocale(Locale?.none)
        }
    }
    
    /**
     Here you can customize captions and texts for some elements
     
     - Parameter text:
     Textual value you want to assign
     - Parameter element:
     UI Element you want to configure
     */
    public func define(text: String?, forElement element: JVDisplayElement) {
        _define(text: text, forElement: element)
    }

    @objc(__defineText:forElementName:)
    public func __define(text: String?, forElement elementName: String) {
        if let element = JVDisplayElement(rawValue: elementName) {
            _define(text: text, forElement: element)
        }
    }

    /**
     Here you can customize colors for some elements
     
     - Parameter color:
     Color value you want to assign
     - Parameter element:
     UI Element you want to configure
     */
    public func define(color: UIColor?, forElement element: JVDisplayElement) {
        _define(color: color, forElement: element)
    }

    @objc(__defineColor:forElementName:)
    public func __define(color hex: String?, forElement elementName: String) {
        if let element = JVDisplayElement(rawValue: elementName) {
            let color = hex.flatMap { UIColor(jv_hex: $0) }
            _define(color: color, forElement: element)
        }
    }

    /**
     Here you can customize icons for some elements
     
     - Parameter image:
     Image value you want to assign
     - Parameter element:
     UI Element you want to configure
     */
    public func define(image: UIImage?, forElement element: JVDisplayElement) {
        _define(image: image, forElement: element)
    }

    @objc(__defineImage:forElementName:)
    public func __define(image name: String?, forElement elementName: String) {
        if let element = JVDisplayElement(rawValue: elementName) {
            let image = name.flatMap { UIImage(named: $0) }
            _define(image: image, forElement: element)
        }
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
    public func setExtraItems(menu: JVDisplayMenu, captions: [String], handler: @escaping (Int) -> Void) {
        _setExtraItems(menu: menu, captions: captions, handler: handler)
    }
    
    @objc(__setExtraItemsForMenu:withCaptions:actionHandler:)
    public func __setExtraItems(menu menuIndex: Int, captions: [String], handler: @escaping (Int) -> Void) {
        if let menu = JVDisplayMenu.allCases.dropFirst(menuIndex).first {
            _setExtraItems(menu: menu, captions: captions, handler: handler)
        }
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
    @discardableResult
    public func place(within navigationController: UINavigationController, closeButton: JVDisplayCloseButton) -> JVSessionHandle? {
        return _place(within: navigationController, closeButton: closeButton)
    }
    
    @objc(placeWithin:closeButton:)
    @discardableResult
    private func place(within navigationController: UINavigationController, closeButton closeIndex: Int) -> JVSessionHandle? {
        if let closeButton = JVDisplayCloseButton.allCases.dropFirst(closeIndex).first {
            return _place(within: navigationController, closeButton: closeButton)
        }
        else {
            return nil
        }
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
    
    #if canImport(SwiftUI)
    /**
     Builds module UI for use within SwiftUI context
     
     - Parameter presentation:
     Determines how module will be presented onscreen
     */
    @available(iOS 13.0, *)
    public func makeScreen(_ presentation: JVDisplayScreenPresentation) -> JVDisplayWrapper {
        return _makeScreen(presentation)
    }
    #endif
    
    /**
     Closes SDK if it is currently in UI hierarchy
     
     - Parameter animated:
     Whether SDK should be closed with animation or not
     */
    @objc(closeAnimated:)
    public func close(animated: Bool) {
        _close(animated: animated)
    }
    
    /**
     Handler will be called when SDK needs to display chat UI on screen
     */
    @objc(listenToAppearanceRequest:)
    public func listenToAppearanceRequest(handler: @escaping () -> Void) {
        callbacks.asksToAppearHandler = handler
    }
    
    /**
     Handler will be called before opening the SDK
     */
    @objc(listenToWillAppear:)
    public func listenToWillAppear(handler: @escaping () -> Void) {
        callbacks.willAppearHandler = handler
    }
    
    /**
     Handler will be called after the SDK is closed
     */
    @objc(listenToDidDisappear:)
    public func listenToDidDisappear(handler: @escaping () -> Void) {
        callbacks.didDisappearHandler = handler
    }
    
    /**
     Handler will be called to customize Header Bar appearance
     */
    @objc(listenToNavigation:)
    public func listenToNavigation(handler: @escaping (UINavigationBar, UINavigationItem) -> Void) {
        callbacks.customizeHeaderHandler = handler
    }
    
    /*
     For private purposes
     */
    private let joint = SdkJoint(engine: SdkEngine.shared)
    internal let callbacks = JVDisplayCallbacks()
}

extension JVDisplayController {
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
            displayCallbacks: callbacks)
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
            displayCallbacks: callbacks)
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
            displayCallbacks: callbacks)
    }
    
    #if canImport(SwiftUI)
    @available(iOS 13.0, *)
    private func _makeScreen(_ presentation: JVDisplayScreenPresentation) -> JVDisplayWrapper {
        journal(layer: .facade) {"FACADE[display] use SwiftUI block as \(presentation)"}
        
        return joint.makeScreen(
            presentation: presentation,
            displayCallbacks: callbacks)
    }
    #endif
    
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
