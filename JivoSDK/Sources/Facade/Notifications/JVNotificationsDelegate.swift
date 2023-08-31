//
//  JVNotificationsDelegate.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Interface to handle notifications events,
 relates to ``Jivo.notifications`` namespace
 */
@objc(JVNotificationsDelegate)
public protocol JVNotificationsDelegate {
    /**
     Called when SDK wants to access Push Notifications
     
     > Tip: You may want to present your custom UI
     > to inform user about accessing to Push Notifications,
     > before SDK will trigger System Request
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter proceedBlock:
     The callback you call when it's time
     to present the System Request for Push Notifications
     */
    @objc(jivoNotificationsAccessRequested:proceedBlock:)
    func jivoNotifications(accessRequested sdk: Jivo, proceedBlock: @escaping () -> Void)
    
    /**
     Called when SDK is going to present Push Notification banner
     
     > Tip: Here you can prepare banner for displaying
     
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
