//
//  JVNotificationsCallbacks.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation
import UserNotifications

/**
 Interface to handle notifications events,
 relates to `Jivo.notifications` namespace
 */
internal final class JVNotificationsCallbacks {
    var accessIntroHandler = { (callback: @escaping () -> Void) in
        callback()
    }
    
    var notificationContentTransformer = { (event: JVNotificationsEvent) -> UNNotificationContent? in
        return event.content
    }
}
