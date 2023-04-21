//
//  UNNotificationPresentationOptions+.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 21.04.2023.
//

import Foundation
import UserNotifications

extension UNNotificationPresentationOptions {
    public static var jv_banner: UNNotificationPresentationOptions {
        if #available(iOS 14.0, *) {
            return .banner
        }
        else {
            return .alert
        }
    }
}
