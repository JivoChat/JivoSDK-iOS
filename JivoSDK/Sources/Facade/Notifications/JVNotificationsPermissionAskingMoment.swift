//
//  JVNotificationsPermissionAskingMoment.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

@objc(JVNotificationsPermissionAskingMoment)
public enum JVNotificationsPermissionAskingMoment: Int {
    /// Don't ask ever
    case never
    
    /// Ask when connected to Jivo
    /// in ``JivoSDKSession/startUp(channelID:userToken:)`` call
    case onConnect
    
    /// Ask when JivoSDK becomes onscreen
    case onAppear
    
    /// Ask when user sends a message
    case onSend
}
