//
//  Config.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 25.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit

struct Config {
    static var isInternalBuild: Bool { return detectDebuggingEnvironment() }
    static var isPublicBuild: Bool { return !isInternalBuild }
    static var isSandboxEnabled: Bool { return detectSandboxEnvironment() }
    
    static let brokenSystemSearch = ConfigRule.betweenOS("13.0", "13.2").resolve
    static let requiresFullScreenNavigation = ConfigRule.betweenOS("13.0", "15.0").resolve

    static let feedbackAvailable = ConfigRule.sinceApp("4.0.3").resolve
    static let worktimeAvailable = ConfigRule.sinceApp("4.1").resolve
    static let phraseEditorAvailable = ConfigRule.sinceApp("4.2").resolve
    static let groupsAvailable = ConfigRule.sinceApp("4.3").resolve
    static let favoriteTagAvailable = ConfigRule.sinceApp("4.3.3").resolve
    static let businessChatAvailable = ConfigRule.sinceApp("4.3.3").resolve
    static let socialSignUpAvailable = ConfigRule.sinceApp("4.4").resolve
    static let appleSignUpAvailable = ConfigRule.sinceApp("4.4").resolve
    static let commentingAvailable = ConfigRule.sinceApp("4.5").resolve
    static let assignedAgentAvailable = ConfigRule.sinceApp("4.5").resolve
    static let quickAnswerAvailable = ConfigRule.sinceApp("4.7").resolve
    static let groupsEditingAvailable = ConfigRule.sinceApp("4.7").resolve
    static let webPointerAvailable = ConfigRule.sinceApp("4.7").resolve
    static let testApnsAvailable = Config.isInternalBuild
    
    static let chatPaginationLimit = 50

    static var currentFeatureID: Int {
//        if feedbackAvailable { return FeaturingFeedbackID }
//        if worktimeAvailable { return FeaturingWorkingTimeID }
//        if feedbackAvailable { return FeaturingOldFeedbackID }
        return 0
    }
}

enum ConfigRule {
    case boolean(Bool)
    case betweenOS(String, String)
    case sinceOS(String)
    case sinceApp(String)
    
    var resolve: Bool {
        switch self {
        case .boolean(let available):
            return available
            
        case .betweenOS(let since, let till):
            let version = UIDevice.current.systemVersion
            return (since.lessOrEqual(then: version) && till.greater(then: version))
            
        case .sinceOS(let since):
            let version = UIDevice.current.systemVersion
            return (since.lessOrEqual(then: version))
            
        case .sinceApp(let since):
            let version = Bundle.main.jv_formatVersion(.marketingShort)
            return since.lessOrEqual(then: version)
        }
    }
}

fileprivate func detectDebuggingEnvironment() -> Bool {
    #if ENV_DEBUG
    return true
    #else
    return false
    #endif
}

fileprivate func detectSandboxEnvironment() -> Bool {
    #if ENV_SANDBOX
    return true
    #else
    return false
    #endif
}

fileprivate extension String {
    func lessOrEqual(then another: String) -> Bool {
        return (compare(another, options: .numeric) != .orderedDescending)
    }
    
    func greater(then another: String) -> Bool {
        return (compare(another, options: .numeric) == .orderedDescending)
    }
}
