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
    @objc public static var session: JVSessionController { shared.session }
    @objc public static var display: JVDisplayController { shared.display }
    @objc public static var notifications: JVNotificationsController { shared.notifications }
    @objc public static var debugging: JVDebuggingController { shared.debugging }
}
