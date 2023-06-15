//
//  ApnsDriver.swift
//  App
//
//  Created by Stan Potemkin on 20.08.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UserNotifications
import PushKit

import JMCodingKit

extension JournalDebuggingToken {
    static let apns = Self(value: "apns")
}

protocol IApnsDriverDelegate: AnyObject {
    func apnsDriver(didReceiveNotification driver: IApnsDriver, meta: ApnsNotificationMeta, response: UNNotificationResponse?, completion: @escaping (Bool) -> Void)
    func apnsDriver(willPresentNotification driver: IApnsDriver, notification: UNNotification, completion: @escaping (UNNotificationPresentationOptions) -> Void)
    func apnsDriver(shouldOpenSettings driver: IApnsDriver, notification: UNNotification?)
    func apnsDriver(didUpdateVoipToken driver: IApnsDriver, token: String?)
    func apnsDriver(didReceiveCallingEvent driver: IApnsDriver, payload: JsonElement, completion: @escaping () -> Void)
}

struct ApnsNotificationMeta {
    let target: ApnsNotificationTarget
    let payload: JsonElement
    let originalDate: Date?
    let userAction: ApnsUserAction
}

enum ApnsNotificationTarget {
    case app
    case sdk
}

enum ApnsUserAction {
    case activateApp
    case performAction(String)
    case dismiss
}

protocol IApnsDriver: AnyObject {
    var delegate: IApnsDriverDelegate? { get set }
    func setupNotifications()
    var voipToken: String? { get }
    func setupCalling()
    func requestForPermission(allowConfiguring: Bool, completion: @escaping (Result<Bool, Error>) -> Void)
    func registerActions(categoryId: String, captions: [String]?)
    func takeRemoteNotification(userInfo: [AnyHashable: Any], originalDate: Date?, actionID: String?, completion: @escaping (Bool) -> Void)
    func detectTarget(userInfo: [AnyHashable: Any]) -> ApnsNotificationTarget
}

final class ApnsDriver: NSObject, IApnsDriver, UNUserNotificationCenterDelegate, PKPushRegistryDelegate {
    weak var delegate: IApnsDriverDelegate?
    
    private var voipRegistry: PKPushRegistry?
    private var handledPayloads = Set<[AnyHashable: AnyHashable]>()

    override init() {
        super.init()
    }
    
    func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    var voipToken: String? {
        return voipRegistry?.pushToken(for: .voIP)?.jv_toHex()
    }
    
    func setupCalling() {
        let registry = PKPushRegistry(queue: .main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        self.voipRegistry = registry
        
        delegate?.apnsDriver(
            didUpdateVoipToken: self,
            token: registry.pushToken(for: .voIP)?.jv_toHex())
    }
    
    func requestForPermission(allowConfiguring: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        let options: UNAuthorizationOptions
        if #available(iOS 12.0, *), allowConfiguring {
            options = [.alert, .badge, .sound, .providesAppNotificationSettings]
        }
        else {
            options = [.alert, .badge, .sound]
        }

        UNUserNotificationCenter.current().requestAuthorization(options: options) { status, error in
            journal {"Received the APNS authorization @status[\(status)] @error[\(String(describing: error))]"}
            
            if status {
                DispatchQueue.main.async(
                    execute: UIApplication.shared.registerForRemoteNotifications
                )
                
                completion(.success(true))
            }
            else if let error = error {
                completion(.failure(error))
            }
            else {
                completion(.success(false))
            }
        }
    }
    
    func registerActions(categoryId: String, captions: [String]?) {
        guard let captions = captions
        else {
            UNUserNotificationCenter.current().setNotificationCategories(Set())
            return
        }
        
        let actions: [UNNotificationAction] = captions.map { caption in
            let data = caption.data(using: .utf8) ?? Data()
            let encoded = categoryId + ":" + data.base64EncodedString()
            return UNNotificationAction(identifier: encoded, title: caption, options: [.authenticationRequired, .foreground])
        }
        
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(
                identifier: categoryId,
                actions: actions,
                intentIdentifiers: [],
                options: []
            )
        ])
    }
    
    func takeRemoteNotification(userInfo: [AnyHashable: Any], originalDate: Date?, actionID: String?, completion: @escaping (Bool) -> Void) {
        guard let equatableUserInfo = userInfo as? [AnyHashable: AnyHashable],
              handledPayloads.insert(equatableUserInfo) == (true, equatableUserInfo)
        else {
            return
        }
        
        let meta = ApnsNotificationMeta(
            target: detectTarget(userInfo: userInfo),
            payload: JsonElement(userInfo),
            originalDate: originalDate,
            userAction: {
                switch actionID {
                case .none:
                    return .activateApp
                case UNNotificationDefaultActionIdentifier:
                    return .activateApp
                case UNNotificationDismissActionIdentifier:
                    return .dismiss
                case .some(let value):
                    return .performAction(value)
                }
            }()
        )
        
        delegate?.apnsDriver(
            didReceiveNotification: self,
            meta: meta,
            response: nil,
            completion: completion)
    }
    
    func detectTarget(userInfo: [AnyHashable: Any]) -> ApnsNotificationTarget {
        if userInfo.keys.contains("jivosdk") {
            return .sdk
        }
        else {
            return .app
        }
    }
    
    internal func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        takeRemoteNotification(
            userInfo: notification.request.content.userInfo,
            originalDate: notification.date,
            actionID: nil,
            completion: { _ in
            })
        
        delegate?.apnsDriver(
            willPresentNotification: self,
            notification: notification,
            completion: completionHandler)
    }

    internal func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let meta = ApnsNotificationMeta(
            target: detectTarget(userInfo: response.notification.request.content.userInfo),
            payload: JsonElement(response.notification.request.content.userInfo),
            originalDate: response.notification.date,
            userAction: {
                switch response.actionIdentifier {
                case UNNotificationDefaultActionIdentifier:
                    return .activateApp
                case UNNotificationDismissActionIdentifier:
                    return .dismiss
                default:
                    return .performAction(response.actionIdentifier)
                }
            }()
        )
        
        delegate?.apnsDriver(
            didReceiveNotification: self,
            meta: meta,
            response: response,
            completion: { _ in completionHandler() })
    }
    
    internal func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        delegate?.apnsDriver(
            shouldOpenSettings: self,
            notification: notification)
    }
    
    internal func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP
        else {
            return
        }

        let token = pushCredentials.token.jv_toHex()
        delegate?.apnsDriver(
            didUpdateVoipToken: self,
            token: token)

        journal(
            layer: .logic,
            subsystem: .general,
            unimessage: {"apns-voip-token: \(token)"}
        )
    }

    internal func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        guard type == .voIP
        else {
            return
        }

        delegate?.apnsDriver(
            didReceiveCallingEvent: self,
            payload: JsonElement(payload.dictionaryPayload),
            completion: {})
    }

    internal func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        guard type == .voIP
        else {
            return
        }

        delegate?.apnsDriver(
            didReceiveCallingEvent: self,
            payload: JsonElement(payload.dictionaryPayload),
            completion: completion)
    }
    
    internal func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP
        else {
            return
        }
        
        delegate?.apnsDriver(
            didUpdateVoipToken: self,
            token: nil)
        
        journal(
            layer: .logic,
            subsystem: .general,
            unimessage: {"apns-voip-no-token"}
        )
    }
}
