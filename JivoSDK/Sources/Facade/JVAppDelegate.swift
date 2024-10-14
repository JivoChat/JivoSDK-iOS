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
 Feel free to use this class as parent for your own App Delegate, for easier SDK integration
 */
@available(*, deprecated)
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
        else {
            completionHandler(.noData)
        }
    }
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let options = Jivo.notifications.willPresent(notification: notification, preferableOptions: .jv_banner) {
            completionHandler(options)
        }
        else {
            completionHandler(.jv_empty)
        }
    }
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Jivo.notifications.didReceive(response: response)
        completionHandler()
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
 Determines a way incoming notifications gets displayed
 */
@available(*, deprecated)
@objc(JVAppBannerPresentingDelegate)
public protocol JVAppBannerPresentingDelegate: AnyObject {
    /**
     Here you can determine UNNotificationPresentationOptions
     to be applied for foreground notifications
     
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
