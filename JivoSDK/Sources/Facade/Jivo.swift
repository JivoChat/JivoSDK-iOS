//
//  JivoSDK.swift
//  JivoSDK
//
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation

/**
 Entry Point to communicate with SDK
 
 > Tip: You can find the full documentation here:
 > https://github.com/JivoChat/JivoSDK-iOS
 */
@objc extension Jivo {
    /**
     Namespace for managing user session

     For details, see ``JVSessionController`` reference
     */
    @objc public static var session: JVSessionController { shared.session }
    
    /**
     Namespace for SDK displaying
     
     For details, see ``JVDisplayController`` reference
     */
    @objc public static var display: JVDisplayController { shared.display }
    
    /**
     Namespace for Push Notifications
     
     For details, see ``JVNotificationsController`` reference
     */
    @objc public static var notifications: JVNotificationsController { shared.notifications }
    
    /**
     Namespace for SDK debugging
     
     For details, see ``JVDebuggingController`` reference
     */
    @objc public static var debugging: JVDebuggingController { shared.debugging }
}
