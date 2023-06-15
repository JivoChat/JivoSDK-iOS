//
//  JVNotificationsTarget.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Target of Push Notification
 */
@objc(JVNotificationsTarget)
public enum JVNotificationsTarget: Int {
    /// Sent by Jivo and intended for JivoSDK
    case sdk
    
    /// Sent by your backend, or by other third-parties
    case app
}
