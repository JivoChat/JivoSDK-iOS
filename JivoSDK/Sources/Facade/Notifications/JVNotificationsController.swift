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
     
     > Important: Call this method from `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
     */
    @objc(setPushTokenData:)
    public func setPushToken(data: Data?) {
        _setPushToken(data: data)
    }
    
    /**
     Associate the Push Token with current user using his userToken in hex-string form
     
     - Parameter hex:
     Push Token as hex string
     
     > Important: Call this method from `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
     */
    @objc(setPushTokenHex:)
    public func setPushToken(hex: String?) {
        _setPushToken(hex: hex)
    }
    
    /**
     Notify about userToken is unavailable
     
     - Parameter error:
     An error from operating system
     
     > Important: Call this method from `application(_:didFailToRegisterForRemoteNotificationsWithError:)`
     */
    @objc(setPushTokenError:)
    public func setPushToken(error: Error) {
        _setPushToken(error: error)
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
     For Swift code
     
     - Parameter userInfo:
     userInfo of Push Notification
     - Returns:
     UIBackgroundFetchResult, if a notification was intended for JivoSDK;
     or nil, otherwise
     
     > Important: Call this method from `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`
     
     > Note: The ``JVDisplayDelegate/jivoDisplay(asksToAppear:)`` method might be called
     > if Push Notification is related to JivoSDK
     */
    public func didReceiveRemoteNotification(userInfo: [AnyHashable : Any]) -> UIBackgroundFetchResult? {
        return _didReceiveRemoteNotification(userInfo: userInfo)
    }
    
    /**
     Processes userInfo of Push Notification
     For ObjC code

     - Parameter userInfo:
     userInfo of Push Notification
     - Parameter completionHandler:
     System handler to call when handling is done
     - Returns:
     true, if a notification was intended for JivoSDK;
     or false, otherwise
     
     > Important: Call this method from `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`
     
     > Note: The ``JVDisplayDelegate/jivoDisplay(asksToAppear:)`` method might be called
     > if Push Notification is related to JivoSDK
     */
    @objc(handleIncomingUserInfo:completionHandler:)
    public func handleIncoming(userInfo: [AnyHashable : Any], completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {
        return _handleIncoming(userInfo: userInfo, completionHandler: completionHandler)
    }
    
    /**
     Determines the presentation options Notification
     For Swift code

     - Parameter notification:
     Incoming Notification
     - Parameter preferableOptions:
     Preferred informing options

     > Important: Call this method from `userNotificationCenter(_:willPresent:withCompletionHandler:)`
     */
    public func willPresent(notification: UNNotification, preferableOptions: UNNotificationPresentationOptions) -> UNNotificationPresentationOptions? {
        return _willPresent(notification: notification, preferableOptions: preferableOptions)
    }
    
    /**
     Determines the presentation options for Push Notification
     For ObjC code

     - Parameter notification:
     Incoming Notification
     - Parameter completionHandler:
     System handler to call when processing is done
     
     > Important: Call this method from `userNotificationCenter(_:willPresent:withCompletionHandler:)`
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
     
     > Important: Call this method from `userNotificationCenter(_:didReceive:withCompletionHandler:)`
     */
    @discardableResult
    @objc(didReceiveResponse:)
    public func didReceive(response: UNNotificationResponse) -> Bool {
        return _didReceive(response: response)
    }
    
    /**
     Processes the User Response
     
     - Parameter response:
     User's response
     - Returns:
     Whether the response was handled by JivoSDK
     
     > Important: Call this method from `userNotificationCenter(_:didReceive:withCompletionHandler:)`
     */
    @available(*, deprecated, renamed: "didReceiveResponse")
    @discardableResult
    @objc(handleUserResponse:)
    public func handleUser(response: UNNotificationResponse) -> Bool {
        return didReceive(response: response)
    }
}

extension JVNotificationsController: SdkEngineAccessing {
    private func _delegateHookDidSet() {
        if let _ = delegate {
            journal {"FACADE[notifications] set the delegate"}
        }
        else {
            journal {"FACADE[notifications] remove the delegate"}
        }
        
        engine.services.apnsService.notificationsDelegate = delegate
        engine.managers.chatManager.notificationsDelegate = delegate
    }
    
    private func _setPermissionAsking(at moment: JVNotificationsPermissionAskingMoment) {
        journal {"FACADE[notifications] ask for permission at @moment[\(moment)]"}
        
        engine.services.apnsService.setAsking(moment: moment)
    }
    
    private func _setPushToken(data: Data?) {
        if let data = data {
            journal {"FACADE[notifications] set the push token\n@data[\(data.jv_toHex())]"}
        }
        else {
            journal {"FACADE[notifications] remove the push token by data"}
        }
        
        engine.managers.clientManager.apnsDeviceLiveToken = data?.jv_toHex()
    }
    
    private func _setPushToken(hex: String?) {
        if let hex = hex {
            journal {"FACADE[notifications] set the push token @hex[\(hex)]"}
        }
        else {
            journal {"FACADE[notifications] remove the push token by hex"}
        }

        engine.managers.clientManager.apnsDeviceLiveToken = hex
    }
    
    private func _setPushToken(error: Error) {
        journal {"FACADE[notifications] failed getting token: \(error as NSError)"}
        
        engine.managers.clientManager.apnsDeviceLiveToken = nil
    }
    
    private func _handleLaunch(options: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        journal {"FACADE[notifications] handle the launch @options[\(options)]"}
        
        if let userInfo = options?[.remoteNotification] as? [AnyHashable: Any] {
            return handleIncoming(userInfo: userInfo, completionHandler: nil)
        }
        else {
            return false
        }
    }
    
    private func _didReceiveRemoteNotification(userInfo: [AnyHashable : Any]) -> UIBackgroundFetchResult? {
        journal {"FACADE[notifications] didReceiveRemoteNotification @userInfo[\(userInfo)]"}
        
        if engine.managers.chatManager.handleNotification(userInfo: userInfo) {
            return .noData
        }
        else {
            return nil
        }
    }
    
    private func _handleIncoming(userInfo: [AnyHashable : Any], completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {
        journal {"FACADE[notifications] handle the notification @userInfo[\(userInfo)]"}
        
        if engine.managers.chatManager.handleNotification(userInfo: userInfo) {
            completionHandler?(.noData)
            return true
        }
        else {
            return false
        }
    }
    
    private func _willPresent(notification: UNNotification, preferableOptions: UNNotificationPresentationOptions) -> UNNotificationPresentationOptions? {
        switch engine.managers.chatManager.handleNotification(notification) {
        case .nonrelated:
            return nil
        case .technical:
            journal {"FACADE[notifications] determine options @userInfo[\(notification.request.content.userInfo)]"}
            return .jv_empty
        case .presentable:
            return preferableOptions
        }
    }
    
    private func _configurePresentation(notification: UNNotification, proxyTo handler: @escaping JVNotificationsOptionsOutput, resolver: @escaping JVNotificationsOptionsResolver) {
        journal {"FACADE[notifications] configure presentation @userInfo[\(notification.request.content.userInfo)]"}
        
        engine.managers.chatManager.prepareToPresentNotification(notification, completionHandler: handler) { target, event in
            return resolver(target, event)
        }
    }
    
    private func _didReceive(response: UNNotificationResponse) -> Bool {
        journal {"FACADE[notifications] didReceive @response[\(response)]"}
        
        return engine.managers.chatManager.handleNotification(response: response)
    }
}

