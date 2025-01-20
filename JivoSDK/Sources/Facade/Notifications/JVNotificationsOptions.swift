//
//  JVNotificationsOptions.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Determines UNNotificationPresentationOptions, based on event parameters
 */
public typealias JVNotificationsOptionsResolver = (JVNotificationsTarget, JVNotificationsCategory) -> UNNotificationPresentationOptions

/**
 Transfers UNNotificationPresentationOptions into system for its internal needs
 */
public typealias JVNotificationsOptionsOutput = (UNNotificationPresentationOptions) -> Void
