//
//  SdkSessionTypes.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 14.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import UserNotifications


enum SessionManagerEvent {
    case endpointConfigUpdated(SdkSessionEndpointConfig)
}

enum NotificationType {
    case remoteIncome
    case localBanner
    case unknown
}

enum SessionAuthorizationState {
    case unknown
    case ready
    case unavailable
}
