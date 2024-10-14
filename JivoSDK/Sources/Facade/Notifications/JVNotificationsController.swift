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

@objc(JVNotificationsContent)
public final class JVNotificationsContent: NSObject {
    public let content: UNMutableNotificationContent
    public let sender: String
    public let text: String
    
    internal init(content: UNMutableNotificationContent, sender: String, text: String) {
        self.content = content
        self.sender = sender
        self.text = text
    }
}

/**
 ``Jivo``.``Jivo/notifications`` namespace for Push Notifications
 */
@objc(JVNotificationsController)
public final class JVNotificationsController: NSObject {
    /**
     Specifies when SDK should request access to Push Notifications
     
     - Parameter moment:
     The moment of requesting access to Push Notifications
     */
    public func setPermissionAsking(at moment: JVNotificationsPermissionAskingMoment) {
        _setPermissionAsking(at: moment)
    }
    
    @objc(setPermissionAsking:)
    private func setPermissionAsking(at momentIndex: Int) {
        if let moment = JVNotificationsPermissionAskingMoment.allCases.dropFirst(momentIndex).first {
            _setPermissionAsking(at: moment)
        }
    }
    
    /**
     Handler will be called when SDK wants to access Push Notifications
     
     The callback you call when it's time
     to present the System Request for Push Notifications
     
     > Tip: You may want to present your custom UI
     > to inform user about accessing to Push Notifications,
     > before SDK will trigger System Request
     */
    @objc(setPermissionIntroProvider:)
    public func setPermissionIntro(provider: @escaping (@escaping () -> Void) -> Void) {
        callbacks.accessIntroHandler = { callback in
            provider(callback)
        }
    }
    
    /**
     Handler will be called when SDK is going to present Push Notification banner
     
     Call the block with adjusted content (if you wish to modify the banner),
     or original content (if you wish to keep things as is),
     or nil (if you wish to avoid showing banner)
     
     > Tip: Here you can prepare banner for displaying
     */
    @objc(setContentTransformerBlock:)
    public func setContentTransformer(block: @escaping (JVNotificationsContent) -> UNNotificationContent?) {
        callbacks.notificationContentTransformer = block
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
    @objc(handleLaunchWithOptions:)
    @discardableResult
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
    
    @objc(didReceiveRemoteNotificationWithUserInfo:)
    private func didReceiveRemoteNotification(userInfo: [AnyHashable : Any]) -> UIBackgroundFetchResult {
        return _didReceiveRemoteNotification(userInfo: userInfo) ?? .noData
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
    @objc(handleIncomingWithUserInfo:completionHandler:)
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
    
    @objc(willPresentNotification:withPreferableOptions:)
    private func willPresent(notification: UNNotification, preferableOptions: UNNotificationPresentationOptions) -> UNNotificationPresentationOptions {
        return _willPresent(notification: notification, preferableOptions: preferableOptions) ?? .jv_empty
    }
    
    /**
     Processes the User Response
     
     - Parameter response:
     User's response
     - Returns:
     Whether the response was handled by JivoSDK
     
     > Important: Call this method from `userNotificationCenter(_:didReceive:withCompletionHandler:)`
     */
    @objc(didReceiveResponse:)
    @discardableResult
    public func didReceive(response: UNNotificationResponse) -> Bool {
        return _didReceive(response: response)
    }
    
    /*
     For private purposes
     */
    private let callbacks = JVNotificationsCallbacks()
    
    internal override init() {
        super.init()
        engine.services.apnsService.notificationsCallbacks = callbacks
        engine.managers.chatManager.notificationsCallbacks = callbacks
    }
}

extension JVNotificationsController: SdkEngineAccessing {
    private func _setPermissionAsking(at moment: JVNotificationsPermissionAskingMoment) {
        journal(layer: .facade) {"FACADE[notifications] ask for permission at @moment[\(moment)]"}
        
        engine.services.apnsService.setAsking(moment: moment)
    }
    
    private func _setPushToken(data: Data?) {
        if let data = data {
            journal(layer: .facade) {"FACADE[notifications] set the push token\n@data[\(data.jv_toHex())]"}
        }
        else {
            journal(layer: .facade) {"FACADE[notifications] remove the push token by data"}
        }
        
        engine.managers.clientManager.apnsDeviceLiveToken = data?.jv_toHex()
    }
    
    private func _setPushToken(hex: String?) {
        if let hex = hex {
            journal(layer: .facade) {"FACADE[notifications] set the push token @hex[\(hex)]"}
        }
        else {
            journal(layer: .facade) {"FACADE[notifications] remove the push token by hex"}
        }

        engine.managers.clientManager.apnsDeviceLiveToken = hex
    }
    
    private func _setPushToken(error: Error) {
        journal(layer: .facade) {"FACADE[notifications] failed getting token: \(error as NSError)"}
        
        engine.managers.clientManager.apnsDeviceLiveToken = nil
    }
    
    private func _handleLaunch(options: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        journal(layer: .facade) {"FACADE[notifications] handle the launch @options[\(String(describing: options))]"}
        
        if let userInfo = options?[.remoteNotification] as? [AnyHashable: Any] {
            return handleIncoming(userInfo: userInfo, completionHandler: nil)
        }
        else {
            return false
        }
    }
    
    private func _didReceiveRemoteNotification(userInfo: [AnyHashable : Any]) -> UIBackgroundFetchResult? {
        journal(layer: .facade) {"FACADE[notifications] didReceiveRemoteNotification @userInfo[\(userInfo)]"}
        
        if engine.managers.chatManager.handleNotification(userInfo: userInfo) {
            return .noData
        }
        else {
            return nil
        }
    }
    
    private func _handleIncoming(userInfo: [AnyHashable : Any], completionHandler: ((UIBackgroundFetchResult) -> Void)?) -> Bool {
        journal(layer: .facade) {"FACADE[notifications] handle the notification @userInfo[\(userInfo)]"}
        
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
            journal(layer: .facade) {"FACADE[notifications] determine options @userInfo[\(notification.request.content.userInfo)]"}
            return .jv_empty
        case .presentable:
            return preferableOptions
        }
    }
    
    private func _didReceive(response: UNNotificationResponse) -> Bool {
        journal(layer: .facade) {"FACADE[notifications] didReceive @response[\(response)]"}
        
        return engine.managers.chatManager.handleNotification(response: response)
    }
}

