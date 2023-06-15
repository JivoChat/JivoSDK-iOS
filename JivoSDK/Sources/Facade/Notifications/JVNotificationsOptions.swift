//
//  JVNotificationsOptions.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Determines how to present the notification, based on its parameters
 */
public typealias JVNotificationsOptionsResolver = (JVNotificationsTarget, JVNotificationsEvent) -> UNNotificationPresentationOptions

/**
 Transfers the determined options into system for its internal needs
 */
public typealias JVNotificationsOptionsOutput = (UNNotificationPresentationOptions) -> Void
