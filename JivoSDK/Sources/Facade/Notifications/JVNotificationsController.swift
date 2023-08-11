//
//  JivoSDKNotificationsImpl.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 12.01.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

/**
 ``Jivo``.``Jivo/notifications`` namespace for Push Notifications
 */
@objc(JVNotificationsController)
public final class JVNotificationsController: NSObject {
    /**
     Object that handles notifications events
     */
    @objc(delegate)
    public weak var delegate = JVNotificationsDelegate?.none {
        didSet {
            _delegateHookDidSet()
        }
    }
    
    /**
     Specifies when SDK should request access to Push Notifications
     
     - Parameter moment:
     The moment of requesting access to Push Notifications
     */
    @objc(setPermissionAskingAt:)
    public func setPermissionAsking(at moment: JVNotificationsPermissionAskingMoment) {
        _setPermissionAsking(at: moment)
    }
    
    /**
     Associate the Push Token with current user using his userToken in raw-binary form
     
     - Parameter data:
     Push Token as raw data
     
     > Important: Call this method from ``UIApplicationDelegate/application(_:didRegisterForRemoteNotificationsWithDeviceToken:)``
     */
    @objc(setPushTokenData:)
    public func setPushToken(data: Data?) {
        _setPushToken(data: data)
    }
    
    /**
     Associate the Push Token with current user using his userToken in hex-string form
     
     - Parameter hex:
     Push Token as hex string
     
     > Important: Call this method from ``UIApplicationDelegate/application(_:didRegisterForRemoteNotificationsWithDeviceToken:)``
     */
    @objc(setPushTokenHex:)
    public func setPushToken(hex: String?) {
        _setPushToken(hex: hex)
    }
    
    /**
     Handle the possible Push Notification
     at the moment of application launching
     
     - Parameter options:
     launchOptions provided by system
     
     > Important: Call this method from `application(_:didFinishLaunchingWithOptions:)`
     */
    @discardableResult
    @objc(handleLaunchOptions:)
    public func handleLaunch(options: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        return _handleLaunch(options: options)
    }
    
    /**
     Processes userInfo of Push Notification
     
     - Parameter userInfo:
     userInfo of Push Notification
     - Parameter completionHandler:
     System handler to call when handling is done
     - Returns:
     true, if a notification was intended for JivoSDK;
     or false, otherwise
     
     > Important: Call this method from ``UIApplicationDelegate/application(_:didReceiveRemoteNotification:fetchCompletionHandler:)``
     
     > Note: The ``JVDisplayDelegate/jivoDisplay(asksToAppear:)`` method might be called
     > if Push Notification is related to JivoSDK
     */
    @objc(handleIncomingUserInfo:completionHandler:)
    public func handleIncoming(userInfo: [AnyHashable : Any], completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {
        return _handleIncoming(userInfo: userInfo, completionHandler: completionHandler)
    }
    
    /**
     Determines the presentation options for Push Notification
     
     - Parameter notification:
     Incoming Notification
     - Parameter completionHandler:
     System handler to call when processing is done
     
     > Important: Call this method from ``userNotificationCenter(_:willPresent:withCompletionHandler:)``
     */
    @objc(configurePresentationForNotification:proxyToHandler:resolver:)
    public func configurePresentation(notification: UNNotification, proxyTo handler: @escaping JVNotificationsOptionsOutput, resolver: @escaping JVNotificationsOptionsResolver) {
        _configurePresentation(notification: notification, proxyTo: handler, resolver: resolver)
    }
    
    /**
     Processes the User Response
     
     - Parameter response:
     User's response
     - Returns:
     Whether the response was handled by JivoSDK
     
     > Important: Call this method from ``userNotificationCenter(_:didReceive:withCompletionHandler:)``
     */
    @discardableResult
    @objc(handleUserResponse:)
    public func handleUser(response: UNNotificationResponse) -> Bool {
        return _handleUser(response: response)
    }
}

extension JVNotificationsController: SdkEngineAccessing {
    private func _delegateHookDidSet() {
        if let _ = delegate {
            journal {"FRONT[notifications] set the delegate"}
        }
        else {
            journal {"FRONT[notifications] remove the delegate"}
        }
        
        engine.services.apnsService.notificationsDelegate = delegate
        engine.managers.chatManager.notificationsDelegate = delegate
    }
    
    private func _setPermissionAsking(at moment: JVNotificationsPermissionAskingMoment) {
        journal {"FRONT[notifications] ask for permission at @moment[\(moment)]"}
        
        engine.services.apnsService.setAsking(moment: moment)
    }
    
    private func _setPushToken(data: Data?) {
        if let data = data {
            journal {"FRONT[notifications] set the push token @data[\(data.jv_toHex())]"}
        }
        else {
            journal {"FRONT[notifications] remove the push token by data"}
        }
        
        engine.managers.clientManager.apnsDeviceLiveToken = data?.jv_toHex()
    }
    
    private func _setPushToken(hex: String?) {
        if let hex = hex {
            journal {"FRONT[notifications] set the push token @hex[\(hex)]"}
        }
        else {
            journal {"FRONT[notifications] remove the push token by hex"}
        }

        engine.managers.clientManager.apnsDeviceLiveToken = hex
    }
    
    private func _handleLaunch(options: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        if let userInfo = options?[.remoteNotification] as? [AnyHashable: Any] {
            return handleIncoming(userInfo: userInfo, completionHandler: nil)
        }
        else {
            return false
        }
    }
    
    private func _handleIncoming(userInfo: [AnyHashable : Any], completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {
        journal {"FRONT[notifications] handle the notification @userInfo[\(userInfo)]"}
        
        if engine.managers.chatManager.handleNotification(userInfo: userInfo) {
            completionHandler?(.noData)
            return true
        }
        else {
            return false
        }
    }
    
    private func _configurePresentation(notification: UNNotification, proxyTo handler: @escaping JVNotificationsOptionsOutput, resolver: @escaping JVNotificationsOptionsResolver) {
        engine.managers.chatManager.prepareToPresentNotification(notification, completionHandler: handler) { target, event in
            return resolver(target, event)
        }
    }
    
    private func _handleUser(response: UNNotificationResponse) -> Bool {
        journal {"FRONT[notifications] handle the notification @response[\(response)]"}
        
        return engine.managers.chatManager.handleNotification(response: response)
    }
}

