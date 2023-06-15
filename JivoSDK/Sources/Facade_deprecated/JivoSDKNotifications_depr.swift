//
//  JivoSDK_Notifications.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 02.04.2023.
//

import Foundation

@available(*, deprecated)
@objc(JivoSDKNotifications)
public class JivoSDKNotifications: NSObject, JVNotificationsDelegate {
    @objc(delegate)
    public var delegate: JivoSDKNotificationsDelegate? {
        didSet {
            Jivo.notifications.delegate = self
        }
    }
    
    @objc(setPermissionAskingAt:handler:)
    public func setPermissionAsking(at moment: JivoSDKNotificationsPermissionAskingMoment, handler: JivoSDKNotificationsPermissionAskingHandler) {
        Jivo.notifications.setPermissionAsking(at: moment.toNewAPI())
    }
    
    @objc(setPushTokenData:)
    public func setPushToken(data: Data?) {
        Jivo.notifications.setPushToken(data: data)
    }
    
    @objc(setPushTokenHex:)
    public func setPushToken(hex: String?) {
        Jivo.notifications.setPushToken(hex: hex)
    }
    
    @objc(handleRemoteNotificationContainingUserInfo:)
    public func handleRemoteNotification(containingUserInfo userInfo: [AnyHashable : Any]) -> Bool {
        return Jivo.notifications.handleIncoming(userInfo: userInfo) { _ in }
    }
    
    @objc(handleNotification:)
    public func handleNotification(_ notification: UNNotification) -> Bool {
        return Jivo.notifications.handleIncoming(userInfo: notification.request.content.userInfo) { _ in }
    }
    
    @objc(handleNotificationResponse:)
    public func handleNotification(response: UNNotificationResponse) -> Bool {
        return Jivo.notifications.handleUser(response: response)
    }
    
    public func jivoNotifications(accessRequested sdk: Jivo, proceedBlock: @escaping () -> Void) {
        delegate?.jivo?(needAccessToNotifications: .shared, proceedBlock: proceedBlock)
    }
    
    public func jivoNotifications(prepareBanner sdk: Jivo, content: UNMutableNotificationContent, sender: String, text: String) -> UNNotificationContent? {
        return content
    }
}

@available(*, deprecated)
@objc(JivoSDKNotificationsPermissionAskingMoment)
public enum JivoSDKNotificationsPermissionAskingMoment: Int {
    case never
    case onConnect
    case onAppear
    case onSend
}

@available(*, deprecated)
@objc(JivoSDKNotificationsPermissionAskingHandler)
public enum JivoSDKNotificationsPermissionAskingHandler: Int {
    case sdk
    case current
}

@available(*, deprecated)
@objc(JivoSDKNotificationsDelegate)
public protocol JivoSDKNotificationsDelegate {
    @objc(jivoNeedAccessToNotifications:proceedBlock:)
    optional func jivo(needAccessToNotifications sdk: JivoSDK, proceedBlock: @escaping () -> Void)
}

fileprivate extension JivoSDKNotificationsPermissionAskingMoment {
    func toNewAPI() -> JVNotificationsPermissionAskingMoment {
        switch self {
        case .never:
            return .never
        case .onConnect:
            return .onConnect
        case .onAppear:
            return .onAppear
        case .onSend:
            return .onSend
        }
    }
}
