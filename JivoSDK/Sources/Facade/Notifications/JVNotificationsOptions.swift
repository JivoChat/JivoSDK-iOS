//
//  JVNotificationsOptions.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

public typealias JVNotificationsOptionsOutput = (UNNotificationPresentationOptions) -> Void
public typealias JVNotificationsOptionsResolver = (JVNotificationsTarget, JVNotificationsEvent) -> UNNotificationPresentationOptions
