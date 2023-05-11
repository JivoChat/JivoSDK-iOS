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
    var accountConfig: SdkClientAccountConfig? { get set }
    var endpointConfig: SdkSessionEndpointConfig? { get set }
    var identifyingToken: String? { get set }
    var localChatId: Int? { get }
    var authorizingPath: String? { get set }
    func reset()
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

struct SdkSessionEndpointConfig {
    let chatserverHost: String
    let chatserverPort: Int?
    let apiHost: String
    let filesHost: String
}

final class SdkSessionContext: ISdkSessionContext {
    let eventSignal = JVBroadcastTool<SdkSessionContextEvent>()
    
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

    public var accountConfig: SdkClientAccountConfig? {
        didSet {
            eventSignal.broadcast(.accountConfigChanged(accountConfig))
        }
    }
    
    var endpointConfig: SdkSessionEndpointConfig?
    
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
//        print("[DEBUG] SessionContext -> Reset identifyingToken")
        accountConfig = nil
        identifyingToken = nil
        authorizingPath = nil
    }
}
