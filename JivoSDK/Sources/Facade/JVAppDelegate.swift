//
//  JVAppDelegate.swift
//  Demo
//
//  Created by Stan Potemkin on 24.02.2023.
//

import Foundation
import UIKit
import UserNotifications

/**
 You may use this class as parent for your own App delegate, for easier SDK integration
 */
@objc(JVAppDelegate)
open class JVAppDelegate: UIResponder
, UIApplicationDelegate
, UNUserNotificationCenterDelegate
, JVAppBannerPresentingDelegate {
    open weak var bannerPresentingDelegate: JVAppBannerPresentingDelegate?
    
    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        bannerPresentingDelegate = self
        Jivo.notifications.handleLaunch(options: launchOptions)
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    open func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Jivo.notifications.setPushToken(data: deviceToken)
    }
    
    open func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Jivo.notifications.setPushToken(data: nil)
    }
    
    open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Jivo.notifications.handleIncoming(userInfo: userInfo, completionHandler: completionHandler) {
            return
        }
        
        completionHandler(.noData)
    }
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Jivo.notifications.configurePresentation(notification: notification, proxyTo: completionHandler) { [weak self] target, event in
            if let handler = self?.bannerPresentingDelegate {
                return handler.jivoApp(bannerPresentation: .shared, target: target, event: event, notification: notification)
            }
            else {
                return .jv_empty
            }
        }
    }
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Jivo.notifications.handleUser(response: response)
    }
    
    open func jivoApp(bannerPresentation sdk: Jivo, target: JVNotificationsTarget, event: JVNotificationsEvent, notification: UNNotification) -> UNNotificationPresentationOptions {
        switch target {
        case .app:
            return []
        case .sdk:
            return [.jv_banner]
        }
    }
}

/**
 Determines how to display incoming notifications
 */
@objc(JVAppBannerPresentingDelegate)
public protocol JVAppBannerPresentingDelegate: AnyObject {
    /**
     Here you can determine what Presentation Options
     have to be applied for foreground notifications
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter target:
     A target the notification is intended for
     - Parameter notification:
     An original incoming notification
     - Returns:
     Presentation Options to be applied for notification
     */
    @objc(jivoAppBannerPresentation:target:event:notification:)
    func jivoApp(bannerPresentation sdk: Jivo, target: JVNotificationsTarget, event: JVNotificationsEvent, notification: UNNotification) -> UNNotificationPresentationOptions
}
