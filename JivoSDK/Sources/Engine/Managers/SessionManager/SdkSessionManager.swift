//
//  SdkSessionManager.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 14.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit
import JWTDecode
import JMCodingKit

protocol ISdkSessionManager: ISdkManager {
    var delegate: JVSessionDelegate? { get set }
    func setPreferredServer(_ server: JVSessionServer)
    func setup(channelPath: String, userToken: String)
    func establishConnection()
}

enum SdkSessionManagerStartupMode {
    case fresh
    case resume
    case reconnect
}

enum SdkSessionManagerStartUpBehavior {
    case newContext
    case previousContext
    case hasAnotherActiveContext
    case alreadyConnecting
}

enum SdkSessionManagerContactInfoAllowance {
    case anyField
    case allFields
}

struct SdkSessionUserIdentity: Equatable {
    let token: String
    let payload: [String: AnyHashable]?
    let id: String?
    
    init(input: String) {
        do {
            let info = try decode(jwt: input)
            token = input
            payload = info.body as? [String: AnyHashable]
            
            let idValue = info.body["id"]
            if idValue == nil {
                id = nil
            }
            else if let idValue = idValue as? String {
                id = idValue
            }
            else {
                assertionFailure("The client-specific 'id' key within JWT payload must have String value")
                id = nil
            }
        }
        catch {
            token = input
            payload = Dictionary()
            id = nil
        }
    }
    
    static func ==(lhs: Self, rhs: Self) -> Bool {
        if lhs.token == rhs.token {
            return true
        }
        else if lhs.payload == rhs.payload {
            return true
        }
        else {
            return false
        }
    }
}

extension PreferencesToken {
    static let contactInfoWasShownAt = Self.init(key: "contactInfoWasShownAt", hint: Date.self)
    static let contactInfoWasEverSent = Self.init(key: "contactInfoWasEverSent", hint: Bool.self)
}

extension KeychainToken {
    static let currentUserNamespace = Self.init(key: "currentUserNamespace", hint: String.self, accessing: .unlockedOnce)
}

fileprivate struct SdkSessionConnectionContext {
    let channelId: String
    let preferredStartupMode: SdkSessionManagerStartupMode
}
 
class SdkSessionManager: SdkManager, ISdkSessionManager {
    private var startUpDeferred: StartUpDeferred?
    private struct StartUpDeferred {
        let channelPath: String
        let userToken: String
    }
    
    private var preferredStartupMode = SdkSessionManagerStartupMode.fresh
    
    // MARK: Constants
    
    private let HOST = 1443
    private let USER_TOKEN_JOIN_SEPARATOR = ":"
    
    // MARK: - Public properties
    
    weak var delegate: JVSessionDelegate?
    
    // MARK: - Private properties
    
    private let sessionContext: ISdkSessionContext
    private let clientContext: ISdkClientContext
    private let messagingContext: ISdkMessagingContext
    private let subStorage: ISdkSessionSubStorage

    private let networking: INetworking
    
    private let apnsService: ISdkApnsService
    private let preferencesDriver: IPreferencesDriver
    private let keychainDriver: IKeychainDriver
    private let reachabilityDriver: IReachabilityDriver
    
    private let uuidProvider: IUUIDProvider
    
    // MARK: - Init
    
    init(
        pipeline: SdkManagerPipeline,
        thread: JVIDispatchThread,
        proto: SdkSessionProto,
        sessionContext: ISdkSessionContext,
        clientContext: ISdkClientContext,
        messagingContext: ISdkMessagingContext,
        networking: INetworking,
        subStorage: ISdkSessionSubStorage,
        networkEventDispatcher: INetworkingEventDispatcher,
        apnsService: ISdkApnsService,
        preferencesDriver: IPreferencesDriver,
        keychainDriver: IKeychainDriver,
        reachabilityDriver: IReachabilityDriver,
        uuidProvider: IUUIDProvider
    ) {
        self.sessionContext = sessionContext
        self.clientContext = clientContext
        self.messagingContext = messagingContext
        self.networking = networking
        self.subStorage = subStorage
        
        self.apnsService = apnsService
        self.preferencesDriver = preferencesDriver
        self.keychainDriver = keychainDriver
        self.reachabilityDriver = reachabilityDriver
        
        self.uuidProvider = uuidProvider
    
        super.init(
            pipeline: pipeline,
            thread: thread,
            userContext: clientContext,
            proto: proto,
            networkEventDispatcher: networkEventDispatcher)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationStateChange),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }
    
    private var proto: ISdkSessionProto {
        return protoAny as! ISdkSessionProto
    }
    
    override func subscribe() {
        super.subscribe()
        
        sessionContext.eventSignal.attachObserver { [weak self] event in
            self?.handleSessionContextEvent(event)
        }
    }
    
    override func run() -> Bool {
        guard super.run()
        else {
            return false
        }
        
        if uuidProvider.isFirstRun {
            keychainDriver.userScope().clearAll()
        }
        
        let path = keychainDriver.userScope().retrieveAccessor(forToken: .connectionUrlPath).string
        sessionContext.authorizingPath = path
        
        if let lastStoredSiteId = keychainDriver.userScope().retrieveAccessor(forToken: .siteID).number,
           let lastStoredChannelId = keychainDriver.userScope().retrieveAccessor(forToken: .channelId).string {
            let lastStoredAccountConfig = SdkClientAccountConfig(siteId: lastStoredSiteId, channelId: lastStoredChannelId)
            sessionContext.accountConfig = lastStoredAccountConfig
        }
        
        reachabilityDriver.start()
        reachabilityDriver.addListener { [unowned self] mode in
            sessionContext.networkingState = mode
            
            switch mode {
            case .cell, .wifi:
                journal(layer: .network) {"Network: \(mode.rawValue)"}
                
                if Jivo.display.isOnscreen {
                    requestConfig()
                }
                
            case .none:
                journal {"Network: none"}
            }
        }
        
        return true
    }
    
    // MARK: - Public methods
    
    func setPreferredServer(_ server: JVSessionServer) {
        thread.async { [unowned self] in
            _setPreferredServer(server)
        }
    }
    
    private func _setPreferredServer(_ server: JVSessionServer) {
        switch server {
        case .auto:
            networking.setPreferredDomain(.auto)
        case .europe:
            networking.setPreferredDomain(.zone(.com))
        case .russia:
            networking.setPreferredDomain(.zone(.ru))
        case .asia:
            networking.setPreferredDomain(.zone(.com))
        default:
            networking.setPreferredDomain(.auto)
        }
    }
    
    func setup(channelPath: String, userToken: String) {
        let applicationState = UIApplication.shared.applicationState
        thread.async { [unowned self] in
            _setup(
                channelPath: channelPath,
                userToken: userToken,
                preferredMode: .resume,
                applicationState: applicationState)
        }
    }
    
    private func _setup(channelPath: String, userToken: String, preferredMode: SdkSessionManagerStartupMode, applicationState: UIApplication.State) {
        let userIdentity = SdkSessionUserIdentity(input: userToken)
        
        guard let meta = detectStartUpMeta(
            channelPath: channelPath,
            userIdentity: userIdentity,
            preferredMode: preferredMode)
        else {
            return
        }
        
        switch meta.behavior {
        case .alreadyConnecting:
            journal {"Connection to socket: already establishing"}
            return
        case .newContext:
            sessionContext.recentStartupMode = .fresh
            keychainDriver.userScope().retrieveAccessor(forToken: .siteID).erase()
            keychainDriver.retrieveAccessor(forToken: .currentUserNamespace).string = meta.personalNamespace
            preferencesDriver.retrieveAccessor(forToken: .contactInfoWasShownAt).erase()
            preferencesDriver.retrieveAccessor(forToken: .contactInfoWasEverSent).erase()
            notifyPipeline(event: .turnInactive(.artifacts))
        case .previousContext where sessionContext.numberOfResumes == 0:
            sessionContext.recentStartupMode = .fresh
        case .previousContext:
            sessionContext.recentStartupMode = (preferredMode == .reconnect ? .reconnect : .resume)
        case .hasAnotherActiveContext:
            sessionContext.connectionAllowance = .disallowed
            notifyPipeline(event: .turnInactive(.connection + .artifacts))
            _setup(channelPath: channelPath, userToken: userToken, preferredMode: .fresh, applicationState: applicationState)
            return
        }
        
        if let domain = meta.endpointInfo.domain {
            networking.setPreferredDomain(domain)
        }
        
        let accountConfig = SdkClientAccountConfig(
            siteId: keychainDriver.userScope().retrieveAccessor(forToken: .siteID).number ?? .zero,
            channelId: meta.endpointInfo.channelId
        )

        sessionContext.updateIdentity(userIdentity)
        sessionContext.accountConfig = accountConfig
        sessionContext.authorizationState = .unknown
        clientContext.personalNamespace = meta.personalNamespace
        
        if let _ = sessionContext.authorizingPath {
            preferredStartupMode = .resume
        }
        
        if applicationState.jv_canCommunicate {
            _startUp_perform()
        }
        else {
            journal(layer: .logic) {"Session: defer the startUp"}
            startUpDeferred = .init(channelPath: channelPath, userToken: userToken)
        }
    }
    
    private func _startUp_perform() {
        apnsService.requestForPermission(at: .sessionSetup)
        
        if sessionContext.raise(connectionState: .identifying) {
            _requestConfig()
        }
    }
    
    private struct _StartUpMeta {
        let endpointInfo: _EndpointInfo
        let personalNamespace: String
        let behavior: SdkSessionManagerStartUpBehavior
    }
    
    private func detectStartUpMeta(channelPath: String, userIdentity: SdkSessionUserIdentity, preferredMode: SdkSessionManagerStartupMode) -> _StartUpMeta? {
        guard let endpointInfo = extractEndpointInfo(channelPath: channelPath)
        else {
            return nil
        }
        
        let personalNamespace = constructPersonalNamespace(
            channelId: endpointInfo.channelId,
            userIdentity: userIdentity)
        
        func _construct(behavior: SdkSessionManagerStartUpBehavior) -> _StartUpMeta {
            journal(layer: .logic) {"StartUp behavior[\(behavior)] for personalNamespace[\(personalNamespace)]"}
            return _StartUpMeta(endpointInfo: endpointInfo, personalNamespace: personalNamespace, behavior: behavior)
        }
        
        if let previousPersonalNamespace = clientContext.personalNamespace, personalNamespace != previousPersonalNamespace {
            return _construct(behavior: .hasAnotherActiveContext)
        }
        
        guard jv_not(networking.isConnecting) else {
            return _construct(behavior: .alreadyConnecting)
        }
        
        let previousAccessor = keychainDriver.retrieveAccessor(forToken: .currentUserNamespace)
        if personalNamespace == previousAccessor.string {
            return _construct(behavior: .previousContext)
        }
        else {
            return _construct(behavior: .newContext)
        }
    }
    
    struct _EndpointInfo {
        let domain: NetworkingDomain?
        let channelId: String
    }
    
    private func extractEndpointInfo(channelPath: String) -> _EndpointInfo? {
        let target = (
            channelPath.contains("/")
            ? channelPath.split(separator: "/").map(String.init)
            : Array()
        )
        
        let server = target.first
        let channelId = target.last ?? channelPath
        
        guard jv_not(channelId.isEmpty)
        else {
            return nil
        }
        
        if let server = server {
            if server.contains(".") {
                return _EndpointInfo(domain: .custom(server), channelId: channelId)
            }
            else {
                return _EndpointInfo(domain: .sandbox(server), channelId: channelId)
            }
        }
        else if target.isEmpty {
            return _EndpointInfo(domain: nil, channelId: channelId)
        }
        else {
            return _EndpointInfo(domain: .zone(.com), channelId: channelId)
        }
    }
    
    private func constructChannelNamespace(channelId: String) -> String {
        return "channel(\(channelId))"
    }
    
    private func constructChannelUserNamespace(channelId: String) -> String {
        return constructChannelNamespace(channelId: channelId) + ":user"
    }
    
    private func constructPersonalNamespace(channelId: String, userIdentity: SdkSessionUserIdentity) -> String {
        if let userId = userIdentity.id {
            return constructChannelUserNamespace(channelId: channelId) + "jwt(\(userId))"
        }
        else {
            return constructChannelUserNamespace(channelId: channelId) + "tmp(\(userIdentity.token))"
        }
    }
    
    private func requestConfig() {
        thread.async { [unowned self] in
            _requestConfig()
        }
    }
    
    private func _requestConfig() {
        guard let channelId = sessionContext.accountConfig?.channelId
        else {
            journal {"Connection to socket: missing channelId"}
            return
        }
        
        proto
            .contextual(object: SdkSessionConnectionContext(
                channelId: channelId,
                preferredStartupMode: .resume
            ))
            .requestConfig(channelId: channelId)
            .silent()
    }
    
    func establishConnection() {
        guard UIApplication.shared.applicationState.jv_canCommunicate else {
            return
        }
        
        thread.async { [unowned self] in
            _establishConnection()
        }
    }
    
    private func _establishConnection() {
        guard let accountConfig = sessionContext.accountConfig,
              let endpointConfig = sessionContext.endpointConfig,
              accountConfig.siteId > .zero
        else {
            sessionContext.connectionAllowance = .allowed
            return
        }
        
        guard !networking.isConnected else {
            journal {"Connection to socket: already connected"}
            return
        }
        
        guard reachabilityDriver.isReachable else {
            journal {"Connection to socket: missing network"}
            sessionContext.connectionState = .searching
            return
        }
        
        func _tryResume() -> Bool {
            guard let path = sessionContext.authorizingPath else {
                return false
            }
            
            return proto.connectToLive(
                host: endpointConfig.chatserverHost,
                port: endpointConfig.chatserverPort,
                credentials: .path(path))
        }
        
        @discardableResult
        func _tryFresh() -> Bool {
            return proto.connectToLive(
                host: endpointConfig.chatserverHost,
                port: endpointConfig.chatserverPort,
                credentials: .ids(
                    siteId: accountConfig.siteId,
                    widgetId: accountConfig.channelId,
                    userToken: sessionContext.userIdentity?.token
                ))
        }
        
        guard sessionContext.raise(connectionState: .connecting) else {
            journal {"Connection to socket: already starting"}
            return
        }
        
        switch preferredStartupMode {
        case .fresh:
            journal {"Session: wanted to start, performing Start"}
            _tryFresh()
        case .resume where _tryResume():
            journal(layer: .logic) {"Session: wanted to resume, performing Resume"}
        case .resume:
            journal(layer: .logic) {"Session: wanted to resume, performing Start"}
            _tryFresh()
        case .reconnect where _tryResume():
            journal(layer: .logic) {"Session: wanted to reconnect, performing Resume"}
        case .reconnect:
            journal(layer: .logic) {"Session: wanted to reconnect, performing Start"}
            _tryFresh()
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
        if subsystems.contains(.config) {
            startUpDeferred = nil
        }
        
        if subsystems.contains(.connection) {
            networking.disconnect()
            sessionContext.authorizationState = .unknown
            sessionContext.connectionState = .disconnected
        }
        
        if subsystems.contains(.artifacts) {
            if let channelId = sessionContext.accountConfig?.channelId {
                let prefix = constructChannelUserNamespace(channelId: channelId)
                keychainDriver.clearNamespace(scopePrefix: prefix)
            }
            
            preferredStartupMode = .fresh
            sessionContext.reset()
        }
    }
    
    private func handleSessionContextEvent(_ event: SdkSessionContextEvent) {
        switch event {
        case .authorizingPathChanged(let path):
            keychainDriver.userScope().retrieveAccessor(forToken: .connectionUrlPath).string = path
        default:
            break
        }
    }
    
    // MARK: BaseManager methods
    
    override func handleProtoEvent(subject: IProtoEventSubject, context: ProtoEventContext?) {
        switch subject as? SdkSessionProtoEventSubject {
        case .connectionConfig(let meta):
            handleConnectionConfig(meta: meta, context: context)
        default:
            break
        }
        
        switch subject as? SdkSessionProtoEventSubject {
        case .socketOpen:
            handleSocketOpenEvent()
        case .socketClose(let kind, let error):
            handleSocketClosedEvent(kind: kind, error: error)
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
        
        journal(layer: .api) {"API: received config\n@response[\(meta.body)]"}
        let parts = meta.body.chatserverHost.split(separator: ":")
        let host = parts.first
        let port = parts.last.flatMap(String.init).flatMap(Int.init) ?? .zero
        
        guard let context = context?.object as? SdkSessionConnectionContext,
              let host = host.flatMap({ "wss://\($0)" })
        else {
            return
        }
        
        keychainDriver.userScope().retrieveAccessor(forToken: .endpoint).string = meta.body.chatserverHost
        keychainDriver.userScope().retrieveAccessor(forToken: .siteID).number = meta.body.siteId
        
        sessionContext.accountConfig = SdkClientAccountConfig(
            siteId: meta.body.siteId,
            channelId: context.channelId
        )
        
        sessionContext.endpointConfig = SdkSessionEndpointConfig(
            chatserverHost: host,
            chatserverPort: port,
            apiHost: "https://\(meta.body.apiHost)",
            filesHost: "https://\(meta.body.filesHost)"
        )
        
        clientContext.licensing = (
            meta.body.isLicensed == false
            ? .unlicensed
            : .licensed
        )
        
        preferredStartupMode = context.preferredStartupMode
        
        switch sessionContext.connectionAllowance {
        case .disallowed:
            break
        case .allowed where sessionContext.reached(connectionState: .connecting):
            break
        case .allowed:
            _establishConnection()
        }
    }
    
    // MARK: - Private methods
    
    private func extractUserToken(clientToken: String) throws -> String? {
        let parts = clientToken.components(separatedBy: USER_TOKEN_JOIN_SEPARATOR)
        
        guard jv_not(parts.isEmpty)
        else {
            throw IntegratorSideUserTokenParsingError.invalidInputDataFormat
        }
        
        return (
            parts.count >= 2
            ? parts.dropFirst().joined(separator: USER_TOKEN_JOIN_SEPARATOR)
            : nil
        )
    }
    
    // MARK: Proto event handling
    
    private func handleSocketOpenEvent() {
        sessionContext.raise(connectionState: .connected)
        sessionContext.numberOfResumes += 1
    }
    
    private func handleSocketClosedEvent(kind: APIConnectionCloseCode, error: Error?) {
        sessionContext.connectionState = .disconnected
        
        switch (kind, sessionContext.authorizationState) {
//        case (.connectionBreak, .unknown):
//            sessionContext.authorizationState = .unavailable
        case (.blacklist, _):
            sessionContext.authorizationState = .unavailable
        case (.sanctions, _):
            sessionContext.authorizationState = .unavailable
        default:
            break
        }
    }
    
    private func handleMeTransaction(_ transaction: [NetworkingEventBundle]) {
        sessionContext.authorizationState = .ready
        
        transaction.forEach { bundle in
            switch bundle.payload.subject as? SdkSessionProtoMeSubject {
            case .urlPath(let path):
                sessionContext.authorizingPath = path
            case .id(let id):
                if let clientId = clientContext.clientId, id != clientId {
                    notifyPipeline(event: .turnInactive(.communication))
                }
                
                clientContext.storeClientId(id, async: thread)
            default:
                break
            }
        }
    }
    
    @objc private func handleApplicationStateChange() {
        if UIApplication.shared.applicationState.jv_canCommunicate, let _ = startUpDeferred {
            journal(layer: .logic) {"Session: use the deferred startUp"}
            startUpDeferred = nil
            
            thread.async { [unowned self] in
                _startUp_perform()
            }
        }
    }
}

private enum IntegratorSideUserTokenParsingError: Error {
    case invalidInputDataFormat
}
