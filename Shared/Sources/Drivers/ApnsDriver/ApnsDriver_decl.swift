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

protocol IApnsDriver: AnyObject {
    var delegate: IApnsDriverDelegate? { get set }
    func setupNotifications()
    var voipToken: String? { get }
    func setupCalling()
    func requestForPermission(allowConfiguring: Bool, completion: @escaping (Result<Bool, Error>) -> Void)
    func registerActions(categoryId: String, captions: [String]?)
    func takeRemoteNotification(userInfo: [AnyHashable: Any], originalDate: Date?, actionID: String?, completion: @escaping (Bool) -> Void)
    func detectTarget(userInfo: [AnyHashable: Any]) -> ApnsNotificationMeta.Target
}

protocol IApnsDriverDelegate: AnyObject {
    func apnsDriver(didReceiveNotification driver: IApnsDriver, meta: ApnsNotificationMeta, response: UNNotificationResponse?, completion: @escaping (Bool) -> Void)
    func apnsDriver(willPresentNotification driver: IApnsDriver, notification: UNNotification, completion: @escaping (UNNotificationPresentationOptions) -> Void)
    func apnsDriver(shouldOpenSettings driver: IApnsDriver, notification: UNNotification?)
    func apnsDriver(didUpdateVoipToken driver: IApnsDriver, token: String?)
    func apnsDriver(didReceiveCallingEvent driver: IApnsDriver, payload: JsonElement, completion: @escaping () -> Void)
}

struct ApnsNotificationMeta {
    let target: Target
    let payload: JsonElement
    let originalDate: Date?
    let userAction: UserAction
}

extension ApnsNotificationMeta {
    enum Target {
        case app
        case sdk
    }

    enum UserAction {
        case activateApp
        case performAction(String)
        case dismiss
    }
}
