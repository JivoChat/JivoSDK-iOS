//
//  SdkClientSubPusher.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 27.04.2021.
//  Copyright © 2021 jivosite.mobile. All rights reserved.
//

import Foundation
import JMCodingKit
import UIKit

protocol ISdkClientSubPusher: INetworkingEventHandler {
    func subscribeToPushes(with credentials: SdkClientSubPusherCredentials, completion: @escaping (Result<SdkClientSubPusherCredentials, SdkClientSubPusherError>) -> Void)
    func unsubscribeFromPushes(exceptActiveCredentials: Bool, unsubscribingResultHandler: @escaping (Result<SdkClientSubPusherCredentials, SdkClientSubPusherError>) -> Void)
}

struct SdkClientSubPusherCredentials: Equatable {
    enum Status {
        case active
        case waitingForSubscribe
        case waitingForUnsubscribe
    }
    
    var id: String {
        return [channelId, clientId, deviceId].joined(separator: ":")
    }
    
    let siteId: Int
    let channelId: String
    let clientId: String
    let deviceId: String
    let deviceLiveToken: String
    let date: Date
    let status: Status
}

enum SdkClientSubPusherError: Error {
    case repositoryInternalError(credentials: [SdkClientSubPusherCredentials])
    case registerRequestFailure(withCode: RestResponseStatus, credentials: SdkClientSubPusherCredentials)
    case unregisterRequestFailure(withCode: RestResponseStatus, credentials: SdkClientSubPusherCredentials)
    case subscriptionIsAlreadyExists(credentials: SdkClientSubPusherCredentials)
    case noCredentialsToUnregister
}

enum SdkClientSubPusherNotificationParsingError: Error {
    case notificationSenderIsNotJivo
}

enum SdkClientSubPusherNotification {
    case message(sender: String, text: String)
    case other
}

enum SdkClientSubPusherNotificationIntent {
    case uiDisplayRequest
}

final class SdkClientSubPusher: ISdkClientSubPusher {
    private let pushCredentialsRepository: PushCredentialsRepository
    private let proto: ISdkClientProto
    private let throttlingQueue: ThrottlingQueue
    
    init(
        pushCredentialsRepository: PushCredentialsRepository,
        proto: ISdkClientProto,
        throttlingQueue: ThrottlingQueue
    ) {
        self.pushCredentialsRepository = pushCredentialsRepository
        self.proto = proto
        self.throttlingQueue = throttlingQueue
    }
    
    func subscribeToPushes(with credentials: SdkClientSubPusherCredentials, completion: @escaping (Result<SdkClientSubPusherCredentials, SdkClientSubPusherError>) -> Void) {
        journal {"APNS: subscribing with credentials\n\(credentials)\n"}
        
        pushCredentialsRepository.allItems { [weak self] items in
            let hasAlreadySubscribed = items
                .filter({ $0.status == .active })
                .contains(where: {
                    $0.id == credentials.id
                    && $0.deviceLiveToken == credentials.deviceLiveToken
                })
            
            let upsertingCredentials = SdkClientSubPusherCredentials(
                siteId: credentials.siteId,
                channelId: credentials.channelId,
                clientId: credentials.clientId,
                deviceId: credentials.deviceId,
                deviceLiveToken: credentials.deviceLiveToken,
                date: credentials.date,
                status: .active
            )
            
            if jv_not(hasAlreadySubscribed) {
                self?.pushCredentialsRepository.upsert([upsertingCredentials]) { _ in
                }
            }
            
            self?.performRegisterRequest(with: upsertingCredentials, completion: completion)
        }
    }
    
    func unsubscribeFromPushes(exceptActiveCredentials: Bool, unsubscribingResultHandler: @escaping (Result<SdkClientSubPusherCredentials, SdkClientSubPusherError>) -> Void) {
        if exceptActiveCredentials {
            journal {"Unsubscribing from APNS except active credentials"}
        }
        else {
            journal {"Unsubscribing from APNS"}
        }
        
        pushCredentialsRepository.allItems { items in
            if !exceptActiveCredentials {
                // Updating SubPusherCredentials.status from .active to .waitingForUnsubscribe to add these credentials to unregister queue
                let upsertingItems = items
                    .filter { $0.status == .active }
                    .map {
                        SdkClientSubPusherCredentials(
                            siteId: $0.siteId,
                            channelId: $0.channelId,
                            clientId: $0.clientId,
                            deviceId: $0.deviceId,
                            deviceLiveToken: $0.deviceLiveToken,
                            date: $0.date,
                            status: .waitingForUnsubscribe
                        )
                    }
                self.pushCredentialsRepository.upsert(upsertingItems) { upsertedItems in
                    if upsertedItems != upsertingItems {
                        return unsubscribingResultHandler(.failure(.repositoryInternalError(credentials: upsertingItems)))
                    }
                }
            }
        }
        
        pushCredentialsRepository.allItems { items in
            let credentialsToUnregister = items
                .filter {
                    if exceptActiveCredentials {
                        return $0.status == .waitingForUnsubscribe
                    } else {
                        return $0.status != .waitingForSubscribe
                    }
                }
                .sorted { $0.date < $1.date }
            if credentialsToUnregister.isEmpty {
                return unsubscribingResultHandler(.failure(.noCredentialsToUnregister))
            }
            credentialsToUnregister.forEach { credentials in
                self.performUnregisterRequest(with: credentials, completion: unsubscribingResultHandler)
            }
        }
    }
    
    func handleProtoEvent(subject: IProtoEventSubject, context: ProtoEventContext?) {
        switch subject as? SessionProtoEventSubject {
        case .pushRegistration(let meta):
            handlePushRegistration(meta: meta, context: context)
        default:
            break
        }
    }
    
    private func handlePushRegistration(meta: ProtoEventSubjectPayload.PushRegistration, context: ProtoEventContext?) {
        guard let context = context?.object as? RequestContext
        else {
            return
        }
        
        let credentials = context.credentials
        let index = "\(credentials.channelId):\(credentials.clientId):\(credentials.deviceId)"
        
        switch (meta.status, context.purpose) {
        case (.success, .registration):
            context.completion(.success(context.credentials))

        case let (status, .registration):
            pushCredentialsRepository.removeItem(withIndex: index) { isItemRemoved in
                if !isItemRemoved {
                    context.completion(.failure(.repositoryInternalError(credentials: [context.credentials])))
                }
            }
            context.completion(.failure(.registerRequestFailure(withCode: status, credentials: context.credentials)))

        case (.success, .unregistering), (.noAccess, .unregistering):
            pushCredentialsRepository.removeItem(withIndex: index) { isItemRemoved in
                if isItemRemoved {
                    context.completion(.success(context.credentials))
                } else {
                    context.completion(.failure(.repositoryInternalError(credentials: [context.credentials])))
                }
            }

        case let (status, .unregistering):
            context.completion(.failure(.unregisterRequestFailure(withCode: status, credentials: context.credentials)))
        }
    }
    
    func handleProtoEvent(transaction: [NetworkingEventBundle]) {
    }
    
    private func performRegisterRequest(with credentials: SdkClientSubPusherCredentials, completion: @escaping (Result<SdkClientSubPusherCredentials, SdkClientSubPusherError>) -> Void) {
        throttlingQueue.enqueue { [unowned self] in
            proto
                .contextual(object: RequestContext(
                    purpose: .registration,
                    credentials: credentials,
                    completion: completion
                ))
                .registerDevice(
                    deviceId: credentials.deviceId,
                    deviceLiveToken: credentials.deviceLiveToken,
                    siteId: credentials.siteId,
                    channelId: credentials.channelId,
                    clientId: credentials.clientId
                )
        }
    }
    
    private func performUnregisterRequest(with credentials: SdkClientSubPusherCredentials, completion: @escaping (Result<SdkClientSubPusherCredentials, SdkClientSubPusherError>) -> Void) {
        throttlingQueue.enqueue { [unowned self] in
            proto
                .contextual(object: RequestContext(
                    purpose: .unregistering,
                    credentials: credentials,
                    completion: completion
                ))
                .registerDevice(
                    deviceId: credentials.deviceId,
                    deviceLiveToken: .jv_empty,
                    siteId: credentials.siteId,
                    channelId: credentials.channelId,
                    clientId: credentials.clientId
                )
        }
    }
}

extension SdkClientSubPusher {
    enum RequestPurpose {
        case registration
        case unregistering
    }
    
    struct RequestContext {
        let purpose: RequestPurpose
        let credentials: SdkClientSubPusherCredentials
        let completion: (Result<SdkClientSubPusherCredentials, SdkClientSubPusherError>) -> Void
    }
}

//class JVPushCredentialsModel: DBModel {
//    @objc dynamic var id: String = ""
//    @objc dynamic var siteId: Int = 0
//    @objc dynamic var channelId: String = ""
//    @objc dynamic var clientId: String = ""
//    @objc dynamic var deviceId: String = ""
//    @objc dynamic var deviceLiveToken: String = ""
//    @objc dynamic var status: String = Status.waitingForRegister.rawValue
//    @objc dynamic var date: Date = Date()
//
//    override func apply(context: ICoreDataContext, change: JVBaseModelChange) {
//        performApply(inside: context, with: change)
//    }
//}
