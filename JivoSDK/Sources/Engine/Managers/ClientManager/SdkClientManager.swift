//
//  SdkClientManager.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 05.10.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

protocol ISdkClientManager: ISdkManager {
    var apnsDeviceLiveToken: String? { get set }
    func setContactInfo(info: JVSessionContactInfo?, allowance: SdkSessionManagerContactInfoAllowance)
    func setCustomData(fields: [JVSessionCustomDataField])
}

class SdkClientManager: SdkManager, ISdkClientManager {
    private let subPusher: ISdkClientSubPusher
    private let sessionContext: ISdkSessionContext
    private let clientContext: ISdkClientContext
    private let uuidProvider: IUUIDProvider
    private let preferencesDriver: IPreferencesDriver
    private var keychainDriver: IKeychainDriver
    
    private var isKeychainStoringEnabled = true
    private var customFields: [JVSessionCustomDataField]?
    
    init(pipeline: SdkManagerPipeline,
         thread: JVIDispatchThread,
         subPusher: ISdkClientSubPusher,
         sessionContext: ISdkSessionContext,
         clientContext: ISdkClientContext,
         proto: ISdkClientProto,
         networkEventDispatcher: INetworkingEventDispatcher,
         uuidProvider: IUUIDProvider,
         preferencesDriver: IPreferencesDriver,
         keychainDriver: IKeychainDriver) {
        self.subPusher = subPusher
        self.sessionContext = sessionContext
        self.clientContext = clientContext
        self.uuidProvider = uuidProvider
        self.preferencesDriver = preferencesDriver
        self.keychainDriver = keychainDriver
    
        super.init(
            pipeline: pipeline,
            thread: thread,
            userContext: clientContext,
            proto: proto,
            networkEventDispatcher: networkEventDispatcher)
    }
    
    private var proto: SdkClientProto {
        return protoAny as! SdkClientProto
    }
    
    private var userContext: ISdkClientContext {
        return userContextAny as! ISdkClientContext
    }
    
    override func subscribe() {
        super.subscribe()
        
        sessionContext.eventSignal.attachObserver { [weak self] event in
            self?.handleSessionContextEvent(event)
        }
        
        clientContext.eventSignal.attachObserver { [weak self] event in
            self?.handleClientContextEvent(event)
        }
    }
    
    override func run() -> Bool {
        guard super.run()
        else {
            return false
        }
        
        restoreClientContext()
        
        return true
    }
    
    var apnsDeviceLiveToken: String? {
        didSet {
            subscribeDeviceToApns()
        }
    }
    
    func setContactInfo(info: JVSessionContactInfo?, allowance: SdkSessionManagerContactInfoAllowance) {
        thread.async { [unowned self] in
            _setContactInfo(info: info, allowance: allowance)
        }
    }
    
    private func _setContactInfo(info: JVSessionContactInfo?, allowance: SdkSessionManagerContactInfoAllowance) {
        guard let info = info
        else {
            clientContext.contactInfo = .init()
            return
        }
        
        switch allowance {
        case .anyField where info.hasAnyField:
            break
        case .anyField:
            return
        case .allFields where info.hasAllFields:
            break
        case .allFields:
            return
        }
        
        clientContext.contactInfo = info
        preferencesDriver.retrieveAccessor(forToken: .contactInfoWasEverSent).boolean = true
        flushClientInfoIfNeeded()
        NotificationCenter.default.post(name: .jv_turnContactFormSnapshot, object: info)
    }
    
    private func flushClientInfoIfNeeded() {
        guard let clientId = clientContext.clientId,
              sessionContext.connectionState == .connected
        else {
            return
        }
        
        proto
            .setContactInfo(
                clientId: clientId,
                name: clientContext.contactInfo.name,
                email: clientContext.contactInfo.email,
                phone: clientContext.contactInfo.phone,
                brief: clientContext.contactInfo.brief)
    }
    
    func setCustomData(fields: [JVSessionCustomDataField]) {
        thread.async { [unowned self] in
            _setCustomData(fields: fields)
        }
    }
    
    private func _setCustomData(fields: [JVSessionCustomDataField]) {
        customFields = fields
        flushCustomDataIfNeeded()
    }
    
    private func flushCustomDataIfNeeded() {
        guard let fields = customFields,
              sessionContext.connectionState == .connected
        else {
            return
        }
        
        customFields = nil
        
        proto
            .setCustomData(fields: fields)
    }
    
    private func restoreClientContext() {
        journal {"Restoring the ClientContext" }
        
        withoutKeychainStoring {
            let clientId = keychainDriver.retrieveAccessor(forToken: .clientId, usingClientToken: true).string
            userContext.clientId = clientId
        }
    }
    
    override func _handlePipeline(event: SdkManagerPipelineEvent) {
        switch event {
        case .turnActive:
            break
        case .turnInactive(let subsystems):
            _handlePipelineTurnInactiveEvent(subsystems: subsystems)
        }
    }
    
    private func _handlePipelineTurnInactiveEvent(subsystems: SdkManagerSubsystem) {
        if subsystems.contains(.artifacts) {
            unsubscribeDeviceFromApns(exceptActiveSubscriptions: false)
            
            withoutKeychainStoring {
                clientContext.reset()
            }
            
            preferencesDriver.retrieveAccessor(forToken: .contactInfoWasShownAt).erase()
            preferencesDriver.retrieveAccessor(forToken: .contactInfoWasEverSent).erase()
        }
    }
    
    private func withoutKeychainStoring(_ block: () -> Void) {
        isKeychainStoringEnabled = false
        block()
        isKeychainStoringEnabled = true
    }
    
    private func storeToKeychain<T>(_ value: T?, ofProperty token: KeychainToken, withType type: ReferenceWritableKeyPath<IKeychainAccessor, T?>, usingClientToken: Bool) {
        if isKeychainStoringEnabled {
            keychainDriver.retrieveAccessor(forToken: token, usingClientToken: usingClientToken)[keyPath: type] = value
        }
    }
    
    private func handleSessionContextEvent(_ event: SdkSessionContextEvent) {
        switch event {
        case .accountConfigChanged(let newAccountConfig):
            accountConfigUpdated(to: newAccountConfig)
        case .identifyingTokenChanged(let token):
            tokenUpdated(to: token)
        default:
            break
        }
    }
    
    private func handleClientContextEvent(_ event: SdkClientContextEvent) {
        switch event {
        case let .clientIdChanged(clientId):
            clientIdUpdated(to: clientId)
        case .licenseStateUpdated:
            break
        case .personalNamespaceChanged:
            break
        }
    }
    
    override func handleProtoEvent(subject: IProtoEventSubject, context: ProtoEventContext?) {
        switch subject as? SdkSessionProtoEventSubject {
        case .connectionConfig(let meta):
            handleConnectionConfig(meta: meta, context: context)
        default:
            break
        }
    }
    
    override func handleProtoEvent(transaction: [NetworkingEventBundle]) {
        let meTransaction = transaction.filter { $0.payload.type == .session(.me) }
        handleMeTransaction(meTransaction)
    }
    
    private func handleConnectionConfig(meta: ProtoEventSubjectPayload.ConnectionConfig, context: ProtoEventContext?) {
        guard meta.status == .success
        else {
            journal {"Failed getting the connection config with @status[\(meta.status)]"}
            return
        }
        
        unsubscribeDeviceFromApns(exceptActiveSubscriptions: true)
    }
    
    private func handleMeTransaction(_ transaction: [NetworkingEventBundle]) {
        transaction.forEach { bundle in
            guard case SdkSessionProtoMeSubject.history(nil) = bundle.payload.subject else {
                return
            }
            
            flushClientInfoIfNeeded()
            flushCustomDataIfNeeded()
            subscribeDeviceToApns()
        }
    }
    
    private func clientIdUpdated(to newClientId: String?) {
        guard let lastClientId = userContext.clientId, lastClientId == newClientId else { return }
        
        storeToKeychain(newClientId, ofProperty: .clientId, withType: \.string, usingClientToken: true)
    }
    
    private func accountConfigUpdated(to newAccountConfig: SdkClientAccountConfig?) {
        if sessionContext.accountConfig != newAccountConfig {
            sessionContext.authorizingPath = nil
        }
        
        storeToKeychain(newAccountConfig?.siteId, ofProperty: .siteId, withType: \.number, usingClientToken: true)
        storeToKeychain(newAccountConfig?.channelId, ofProperty: .channelId, withType: \.string, usingClientToken: true)
    }
    
    private func tokenUpdated(to token: String?) {
        let lastStoredToken = keychainDriver.retrieveAccessor(forToken: .token).string
        if lastStoredToken != token {
            storeToKeychain(token, ofProperty: .token, withType: \.string, usingClientToken: false)
            restoreClientContext()
        }
    }
    
    private func subscribeDeviceToApns() {
        guard let accountConfig = sessionContext.accountConfig,
              accountConfig.siteId > 0,
              let clientId = clientContext.clientId,
              let apnsLiveToken = apnsDeviceLiveToken
        else {
            return
        }
        
        let deviceId = uuidProvider.currentDeviceID
        journal {"APNS: going to subscribe\ndeviceId[\(deviceId)]"}
        
        let credentials = SdkClientSubPusherCredentials(
            siteId: accountConfig.siteId,
            channelId: accountConfig.channelId,
            clientId: clientId,
            deviceId: deviceId,
            deviceLiveToken: apnsLiveToken,
            date: Date(),
            status: .waitingForSubscribe
        )
        
        subPusher.subscribeToPushes(with: credentials) { [weak self] result in
            self?.handleSubPusherResult(result, of: .subscribing)
        }
    }
    
    private func unsubscribeDeviceFromApns(exceptActiveSubscriptions: Bool) {
        subPusher.unsubscribeFromPushes(exceptActiveCredentials: exceptActiveSubscriptions) { [weak self] result in
            self?.handleSubPusherResult(result, of: .unsubscribing)
        }
    }
    
    private func handleSubPusherResult(_ result: Result<SdkClientSubPusherCredentials, SdkClientSubPusherError>, of action: SubPusherAction) {
        switch result {
        case let .success(credentials):
            switch action {
            case .subscribing:
                journal {"APNS: subscribed with credentials\n\(credentials)\n"}
            case .unsubscribing:
                journal {"APNS: unsubscribed with credentials\n\(credentials)\n"}
            }
            
        case let .failure(error):
            switch error {
            case let .repositoryInternalError(credentials):
                journal {"APNS: failed unsubscribing, repository internal error for credentials\n\(credentials)\n"}
                
            case let .unregisterRequestFailure(status, credentials):
                journal {"APNS: failed unsubscribing, request status[\(status)] for credentials\n\(credentials)\n"}
                
            case let .registerRequestFailure(status, credentials):
                journal {"APNS: failed subscribing, request status[\(status)] for credentials\n\(credentials)\n"}
                
            case .subscriptionIsAlreadyExists(credentials: let credentials):
                journal {"APNS: already subscribed with credentials\n\(credentials)\n"}
                
            case .noCredentialsToUnregister:
                journal {"APNS: no credentials in unsubscribing queue"}
            }
        }
    }
}

extension SdkClientManager {
    enum SubPusherAction {
        case subscribing
        case unsubscribing
    }
}
