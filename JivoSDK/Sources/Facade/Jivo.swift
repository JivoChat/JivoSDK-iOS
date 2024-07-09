//
//  JivoSDK.swift
//  JivoSDK
//
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation

/**
 For quick access the Documentation,
 please call the context menu on "Jivo" namespace below,
 and click "Show Quick Help"
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
