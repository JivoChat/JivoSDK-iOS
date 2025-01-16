//
//  JVNotificationsPermissionAskingMoment.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Moment to request access to Push Notifications
 */
public enum JVNotificationsPermissionAskingMoment: String, CaseIterable {
    /// Don't ask ever
    case never
    
    /// Ask when connected to Jivo
    /// in ``JVSessionController/setup(widgetID:clientIdentity:)`` call
    case sessionSetup // previously "onConnect"
    
    /// Ask when JivoSDK becomes onscreen
    case displayOnscreen // previously "onAppear"
    
    /// Ask when user performs any action (like sending a message)
    case clientAction // previously "onSend"
}
