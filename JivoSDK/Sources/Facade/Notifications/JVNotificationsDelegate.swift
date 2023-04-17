//
//  JVNotificationsDelegate.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

@objc(JVNotificationsDelegate)
public protocol JVNotificationsDelegate {
    /**
     Informs about JivoSDK wants to access Push Notifications
     
     > Tip: You may want to present your custom UI
     > to inform user about Push Notifications,
     > before the JivoSDK will trigger the System Request
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter proceedBlock:
     The callback you call when it's time
     to present the System Request for Push Notifications
     */
    @objc(jivoNotificationsAccessRequested:proceedBlock:)
    func jivoNotifications(accessRequested sdk: Jivo, proceedBlock: @escaping () -> Void)
    
    /**
     Here you can prepare the Push Notification Banner
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter content:
     Original object provided by system
     - Parameter sender:
     Display name of person who sent the message
     - Parameter text:
     Textual preview of sent message
     - Returns:
     Adjusted content (if you wish to modify the banner),
     or original content (if you wish to keep things as is),
     or nil (if you wish to avoid showing banner)
     */
    @objc(jivoNotificationsPrepareBanner:content:sender:text:)
    func jivoNotifications(prepareBanner sdk: Jivo, content: UNMutableNotificationContent, sender: String, text: String) -> UNNotificationContent?
}
