//
//  JivoSDK_deprecated.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 02.04.2023.
//

import Foundation

@available(*, deprecated, renamed: "Jivo")
@objc(JivoSDK)
public final class JivoSDK: NSObject {
    public typealias Jivo = JivoSDK
    
    @objc public static let shared = JivoSDK()
    private override init() {
        super.init()
    }
    
    @objc public let session = JivoSDKSession()
    @objc public static var session: JivoSDKSession { shared.session }
    
    @objc public let chattingUI = JivoSDKChattingUI()
    @objc public static var chattingUI: JivoSDKChattingUI { shared.chattingUI }
    
    @objc public let notifications = JivoSDKNotifications()
    @objc public static var notifications: JivoSDKNotifications { shared.notifications }
    
    @objc public let debugging = JivoSDKDebugging()
    @objc public static var debugging: JivoSDKDebugging { shared.debugging }
}
