//
//  SdkSessionManager.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 14.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import JivoFoundation
import JWTDecode
import JMCodingKit

protocol ISdkSessionManager: ISdkManager {
    var delegate: JVSessionDelegate? { get set }
    func setPreferredServer(_ server: JVSessionServer)
    func startUp(channelPath: String, clientToken: String)
    func requestConfig()
    func establishConnection()
}

enum SdkSessionManagerStartupMode {
    case fresh
    case resume
}

enum SdkSessionManagerStartUpBehavior {
    case newContext(personalNamespace: String)
    case previousContext
    case hasAnotherActiveContext
    case alreadyConnecting
}

enum SdkSessionManagerContactInfoAllowance {
    case anyField
    case allFields
}

extension PreferencesToken {
    static let contactInfoWasShownAt = Self.init(key: "contactInfoWasShownAt", hint: Date.self)
    static let contactInfoWasEverSent = Self.init(key: "contactInfoWasEverSent", hint: Bool.self)
}

extension KeychainToken {
    static let previousPersonalNamespace = Self.init(key: "previousToken", hint: String.self, accessing: .unlockedOnce)
}

fileprivate struct SdkSessionConnectionContext {
    let channelId: String
    let preferredStartupMode: SdkSessionManagerStartupMode
}

class SdkSessionManager: SdkManager, ISdkSessionManager {
    private var startUpDeferred: StartUpDeferred?
    private struct StartUpDeferred {
        let channelPath: String
        let clientToken: String
    }
    
    private var channelId: String?
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
        
        let path = keychainDriver.retrieveAccessor(forToken: .connectionUrlPath, usingClientToken: true).string
        sessionContext.authorizingPath = path
        
        if let lastStoredSiteId = keychainDriver.retrieveAccessor(forToken: .siteId).number,
           let lastStoredChannelId = keychainDriver.retrieveAccessor(forToken: .channelId).string {
            let lastStoredAccountConfig = SdkClientAccountConfig(siteId: lastStoredSiteId, channelId: lastStoredChannelId)
            sessionContext.accountConfig = lastStoredAccountConfig
        }
        
        reachabilityDriver.start()
        reachabilityDriver.addListener { [unowned self] mode in
            self.sessionContext.networkingState = mode
            
            switch mode {
            case .cell, .wifi:
                journal {"Currently reachable via: \(mode.rawValue)"}
                
                if Jivo.display.isOnscreen {
                    requestConfig()
                }
                
            case .none:
                break
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
    
    func startUp(channelPath: String, clientToken: String) {
        guard UIApplication.shared.jv_isActive
        else {
            startUpDeferred = .init(channelPath: channelPath, clientToken: clientToken)
            return
        }
        
        thread.async { [unowned self] in
            _startUp(
                channelPath: channelPath,
                clientToken: clientToken,
                preferredMode: .resume)
        }
    }
    
    private func _startUp(channelPath: String, clientToken: String, preferredMode: SdkSessionManagerStartupMode) {
//        print("[DEBUG] SessionManager -> will start up with identifying token '\(clientToken)' in '\(preferredMode)' mode")
        
        guard let meta = detectStartUpMeta(
            channelPath: channelPath,
            clientToken: clientToken,
            preferredMode: preferredMode)
        else {
//            print("[DEBUG] SessionManager -> abort with no meta")
            return
        }
        
//        print("[DEBUG] SessionManager -> starting up with behavior \(meta.behavior)")
        
        switch meta.behavior {
        case .alreadyConnecting:
            journal {"Connection to socket: already establishing"}
            return
        case .newContext:
            keychainDriver.retrieveAccessor(forToken: .siteID).erase()
            keychainDriver.retrieveAccessor(forToken: .previousPersonalNamespace).string = meta.personalNamespace
            preferencesDriver.retrieveAccessor(forToken: .contactInfoWasShownAt).erase()
            preferencesDriver.retrieveAccessor(forToken: .contactInfoWasEverSent).erase()
            notifyPipeline(event: .turnInactive(.artifacts))
//            _startUp(channelPath: channelPath, clientToken: clientToken, preferredMode: .fresh)
//            return
        case .previousContext:
            break
        case .hasAnotherActiveContext:
            sessionContext.connectionAllowance = .disallowed
            notifyPipeline(event: .turnInactive(.connection + .artifacts))
            _startUp(channelPath: channelPath, clientToken: clientToken, preferredMode: .fresh)
            return
        }
        
        do {
            let jwt = try decode(jwt: clientToken)
            if jv_not(jwt.body.keys.contains("id")) {
                inform {"The userToken must contain mandatory 'id' key inside its JWT body"}
            }
        }
        catch {
            inform {"For better integration, the userToken should be JWT"}
        }
        
        if let domain = meta.endpointInfo.domain {
            networking.setPreferredDomain(domain)
        }
        
        let accountConfig = SdkClientAccountConfig(
            siteId: keychainDriver.retrieveAccessor(forToken: .siteID).number,
            channelId: meta.endpointInfo.channelId
        )

        sessionContext.identifyingToken = clientToken
        sessionContext.accountConfig = accountConfig
        clientContext.personalNamespace = meta.personalNamespace
        
        apnsService.requestForPermission(at: .onConnect)
        
        sessionContext.connectionState = .identifying
        _requestConfig()
    }
    
    private struct _StartUpMeta {
        let endpointInfo: _EndpointInfo
        let personalNamespace: String
        let behavior: SdkSessionManagerStartUpBehavior
    }
    
    private func detectStartUpMeta(channelPath: String, clientToken: String, preferredMode: SdkSessionManagerStartupMode) -> _StartUpMeta? {
        guard let endpointInfo = extractEndpointInfo(channelPath: channelPath)
        else {
            return nil
        }
        
        let personalNamespace = constructPersonalNamespace(endpointInfo.channelId, clientToken)
        func _construct(behavior: SdkSessionManagerStartUpBehavior) -> _StartUpMeta {
            return _StartUpMeta(endpointInfo: endpointInfo, personalNamespace: personalNamespace, behavior: behavior)
        }
        
        if let previousPersonalNamespace = clientContext.personalNamespace, personalNamespace != previousPersonalNamespace {
            return _construct(behavior: .hasAnotherActiveContext)
        }
        
        guard jv_not(networking.isConnecting) else {
            return _construct(behavior: .alreadyConnecting)
        }
        
        let previousAccessor = keychainDriver.retrieveAccessor(forToken: .previousPersonalNamespace)
        if personalNamespace == previousAccessor.string {
            return _construct(behavior: .previousContext)
        }
        else {
            return _construct(behavior: .newContext(personalNamespace: personalNamespace))
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
        
        if let server = server, server.contains(".") {
            return _EndpointInfo(domain: .custom(server), channelId: channelId)
        }
        else if target.isEmpty {
            return _EndpointInfo(domain: nil, channelId: channelId)
        }
        else {
            return _EndpointInfo(domain: .zone(.com), channelId: channelId)
        }
    }
    
    private func constructPersonalNamespace(_ arguments: String?...) -> String {
        return arguments
            .jv_flatten()
            .joined(separator: String(USER_TOKEN_JOIN_SEPARATOR))
    }
    
    func requestConfig() {
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
        thread.async { [unowned self] in
            _establishConnection()
        }
    }
    
    private func _establishConnection() {
        guard let accountConfig = sessionContext.accountConfig,
              let endpointConfig = sessionContext.endpointConfig,
              let siteId = accountConfig.siteId
        else {
            sessionContext.connectionAllowance = .allowed
            return
        }
        
        guard sessionContext.connectionState != .connecting
        else {
            journal {"Connection to socket: already starting"}
            return
        }
        
        guard !networking.isConnected
        else {
            journal {"Connection to socket: already connected"}
            return
        }
        
        guard reachabilityDriver.isReachable
        else {
            journal {"Connection to socket: missing network"}
            sessionContext.connectionState = .searching
            return
        }
        
        func _tryResume() -> Bool {
            guard let path = sessionContext.authorizingPath
            else {
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
                    siteId: siteId,
                    widgetId: accountConfig.channelId,
                    clientToken: sessionContext.identifyingToken
                ))
        }
        
        sessionContext.connectionState = .connecting
        
        switch preferredStartupMode {
        case .resume where _tryResume():
            journal {"Wanted to resume, and performing the Resume"}
        case .resume:
            journal {"Wanted to resume, but performing the Start"}
            _tryFresh()
        case .fresh:
            journal {"Wanted to start, and performing the Start"}
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
            sessionContext.connectionState = .disconnected
        }
        
        if subsystems.contains(.artifacts) {
            sessionContext.reset()
        }
    }
    
    private func handleSessionContextEvent(_ event: SdkSessionContextEvent) {
        switch event {
        case .authorizingPathChanged(let path):
            keychainDriver.retrieveAccessor(forToken: .connectionUrlPath, usingClientToken: true).string = path
        default:
            break
        }
    }
    
    // MARK: BaseManager methods
    
    override func handleProtoEvent(subject: IProtoEventSubject, context: ProtoEventContext?) {
        switch subject as? SessionProtoEventSubject {
        case .connectionConfig(let meta):
            handleConnectionConfig(meta: meta, context: context)
        default:
            break
        }
        
        switch subject as? SessionProtoEventSubject {
        case .socketOpen:
            handleSocketOpenEvent()
        case .socketClose(let kind, let error):
            handleSocketClosedEvent(kind: kind, error: error)
        default:
            break
        }
    }
    
    override func handleProtoEvent(transaction: [NetworkingEventBundle]) {
        let meTransaction = transaction.filter { $0.payload.type == ProtoTransactionKind.session(.me) }
        handleMeTransaction(meTransaction)
    }
    
    private func handleConnectionConfig(meta: ProtoEventSubjectPayload.ConnectionConfig, context: ProtoEventContext?) {
        guard meta.status == .success
        else {
            journal {"Failed getting the connection config with @status[\(meta.status)]"}
            return
        }
        
        journal {"Received the connection config with @response[\(meta.body)]"}
        let parts = meta.body.chatserverHost.split(separator: ":")
        let host = parts.first
        let port = parts.last.flatMap(String.init).flatMap(Int.init)
        
        guard let context = context?.object as? SdkSessionConnectionContext,
              let host = host.flatMap({ "wss://\($0)" })
        else {
            return
        }
        
        keychainDriver.retrieveAccessor(forToken: .siteID).number = meta.body.siteId
        
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
        journal {"Socket opened"}
        sessionContext.connectionState = .connected
    }
    
    private func handleSocketClosedEvent(kind: APIConnectionCloseCode, error: Error?) {
        journal {"Socket closed of kind[\(kind)] with error[\(error?.localizedDescription ?? "")]"}
        sessionContext.connectionState = .disconnected
    }
    
    private func handleMeTransaction(_ transaction: [NetworkingEventBundle]) {
        transaction.forEach { bundle in
            switch bundle.payload.subject as? MeTransactionSubject {
            case .meUrlPath(let path):
                sessionContext.authorizingPath = path
            case .meId(let id):
                clientContext.clientId = id
            default:
                break
            }
        }
    }
    
    @objc private func handleApplicationStateChange() {
        if UIApplication.shared.jv_isActive, let deferred = startUpDeferred {
            startUpDeferred = nil
            
            thread.async { [unowned self] in
                _startUp(
                    channelPath: deferred.channelPath,
                    clientToken: deferred.clientToken,
                    preferredMode: .resume)
            }
        }
    }
}

private enum IntegratorSideUserTokenParsingError: Error {
    case invalidInputDataFormat
}
