//
//  SdkSessionContext.swift
//  SDK
//
//  Created by Stan Potemkin on 26.02.2023.
//

import Foundation

protocol ISdkSessionContext: AnyObject {
    var eventSignal: JVBroadcastTool<SdkSessionContextEvent> { get }
    var networkingState: ReachabilityMode { get set }
    var connectionAllowance: SdkSessionConnectionAllowance { get set }
    var connectionState: SdkSessionConnectionState { get set }
    var authorizationState: SessionAuthorizationState { get set }
    var authorizationStateSignal: JVBroadcastUniqueTool<SessionAuthorizationState> { get }
    var accountConfig: SdkClientAccountConfig? { get set }
    var endpointConfig: SdkSessionEndpointConfig? { get set }
    var rateConfig: JMTimelineRateConfig? { get set }
    var recentStartupMode: SdkSessionManagerStartupMode { get set }
    var recentStartupModeSignal: JVBroadcastUniqueTool<SdkSessionManagerStartupMode> { get }
    var numberOfResumes: Int { get set }
    var identifyingToken: String? { get set }
    var localChatId: Int? { get }
    var authorizingPath: String? { get set }
    func reset()
}

extension PreferencesToken {
    static let accountConfig = PreferencesToken(key: "accountConfig", hint: SdkClientAccountConfig.self)
    static let endpointConfig = PreferencesToken(key: "endpointConfig", hint: SdkSessionEndpointConfig.self)
    static let rateConfig = PreferencesToken(key: "rateConfig", hint: JMTimelineRateConfig.self)
}

enum SdkSessionContextEvent {
    case networkingStateChanged(ReachabilityMode)
    case connectionStateChanged(SdkSessionConnectionState)
    case accountConfigChanged(SdkClientAccountConfig?)
    case identifyingTokenChanged(String?)
    case authorizingPathChanged(String?)
}

enum SdkSessionConnectionAllowance {
    case allowed
    case disallowed
}

enum SdkSessionConnectionState {
    case disconnected
    case searching
    case identifying
    case connecting
    case connected
}

struct SdkSessionEndpointConfig: Codable {
    let chatserverHost: String
    let chatserverPort: Int
    let apiHost: String
    let filesHost: String
}

final class SdkSessionContext: ISdkSessionContext {
    let eventSignal = JVBroadcastTool<SdkSessionContextEvent>()
    
    private let accountConfigAccessor: IPreferencesAccessor
    private let endpointConfigAccessor: IPreferencesAccessor
    private let rateConfigAccessor: IPreferencesAccessor
    
    init(accountConfigAccessor: IPreferencesAccessor, endpointConfigAccessor: IPreferencesAccessor, rateConfigAccessor: IPreferencesAccessor) {
        self.accountConfigAccessor = accountConfigAccessor
        self.endpointConfigAccessor = endpointConfigAccessor
        self.rateConfigAccessor = rateConfigAccessor
         
        accountConfig = accountConfigAccessor.accountConfig
        endpointConfig = endpointConfigAccessor.endpointConfig
        rateConfig = rateConfigAccessor.rateConfig
    }
    
    var networkingState = ReachabilityMode.none {
        didSet {
            eventSignal.broadcast(.networkingStateChanged(networkingState))
//            print("[DEBUG] SdkSessionContext.connectionState = \(connectionState)")
        }
    }

    var connectionAllowance = SdkSessionConnectionAllowance.disallowed {
        didSet {
            eventSignal.broadcast(.connectionStateChanged(connectionState))
//            print("[DEBUG] SdkSessionContext.connectionState = \(connectionState)")
        }
    }

    var connectionState = SdkSessionConnectionState.disconnected {
        didSet {
            eventSignal.broadcast(.connectionStateChanged(connectionState))
//            print("[DEBUG] SdkSessionContext.connectionState = \(connectionState)")
        }
    }

    let authorizationStateSignal = JVBroadcastUniqueTool<SessionAuthorizationState>()
    var authorizationState = SessionAuthorizationState.unknown {
        didSet {
            authorizationStateSignal.broadcast(authorizationState, async: .main)
        }
    }

    var accountConfig: SdkClientAccountConfig? {
        didSet {
            accountConfigAccessor.accountConfig = accountConfig
            eventSignal.broadcast(.accountConfigChanged(accountConfig))
        }
    }
    
    var endpointConfig: SdkSessionEndpointConfig? {
        didSet {
            endpointConfigAccessor.endpointConfig = endpointConfig
        }
    }
    
    var rateConfig: JMTimelineRateConfig? {
        didSet {
            rateConfigAccessor.rateConfig = rateConfig
        }
    }
    
    let recentStartupModeSignal = JVBroadcastUniqueTool<SdkSessionManagerStartupMode>()
    var recentStartupMode = SdkSessionManagerStartupMode.fresh {
        didSet {
            recentStartupModeSignal.broadcast(recentStartupMode, async: .main)
        }
    }
    
    var numberOfResumes = 0
    
    var identifyingToken: String? {
        didSet {
            eventSignal.broadcast(.identifyingTokenChanged(identifyingToken))
        }
    }
    
    var localChatId: Int? {
        guard let identifyingToken = identifyingToken else {
            journal {"Failed obtaining a chat because clientToken doesn't exists"}
            return nil
        }
        
        let chatId = max(1, CRC32.encrypt(identifyingToken))
        return chatId
    }
    
    var authorizingPath: String? {
        didSet {
            eventSignal.broadcast(.authorizingPathChanged(authorizingPath))
        }
    }
    
    func reset() {
        authorizationState = .unknown
        accountConfig = nil
        identifyingToken = nil
        authorizingPath = nil
        numberOfResumes = 0
    }
}

extension IPreferencesAccessor {
    var accountConfig: SdkClientAccountConfig? {
        get {
            data.flatMap { try? JSONDecoder().decode(SdkClientAccountConfig.self, from: $0) }
        }
        set {
            data = try? JSONEncoder().encode(newValue)
        }
    }
    
    var endpointConfig: SdkSessionEndpointConfig? {
        get {
            data.flatMap { try? JSONDecoder().decode(SdkSessionEndpointConfig.self, from: $0) }
        }
        set {
            data = try? JSONEncoder().encode(newValue)
        }
    }
    
    var rateConfig: JMTimelineRateConfig? {
        get {
            data.flatMap { try? JSONDecoder().decode(JMTimelineRateConfig.self, from: $0) }
        }
        set {
            data = try? JSONEncoder().encode(newValue)
        }
    }
}
