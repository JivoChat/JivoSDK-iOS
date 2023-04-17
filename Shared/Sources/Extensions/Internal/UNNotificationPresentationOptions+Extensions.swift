//
//  UNNotificationPresentationOptions+Extensions.swift
//  App
//
//  Created by Anton Karpushko on 11.01.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UserNotifications

extension UNNotificationPresentationOptions {
    static var bannerOrAlert: UNNotificationPresentationOptions {
        if #available(iOS 14.0, *) {
            return .banner
        }
        else {
            return .alert
        }
    }
}
