//
//  NetworkingContext.swift
//  App
//
//  Created by Stan Potemkin on 07.04.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

final class NetworkingContext: INetworkingContext {
    let localeProvider: JVILocaleProvider
    
    private let mGlobalDomain = "jivosite.com"
    private let mRussianDomain = "jivo.ru"
    private let settingsKey = "jivo:connectivity.connection_type"
    
    private var domain = NetworkingDomain.auto
    
    init(localeProvider: JVILocaleProvider) {
        self.localeProvider = localeProvider
    }
    
    var primaryDomain: String {
        switch domain {
        case .auto:
            break
        case .zone(id: .com):
            return mGlobalDomain
        case .zone(id: .ru):
            return mRussianDomain
        case .sandbox(let prefix):
            return "\(prefix).dev.\(mGlobalDomain)"
        case .custom(let host):
            return host
        }
        
        switch UserDefaults.standard.string(forKey: settingsKey) {
        case "pgtn", "eu", "asia":
            return mGlobalDomain
        case "srtn", "ru":
            return mRussianDomain
        default:
            break
        }
        
        switch (true) {
        case localeProvider.isPossibleGlobal:
            return mGlobalDomain
        case localeProvider.isPossibleRussia:
            return mRussianDomain
        default:
            return mGlobalDomain
        }
    }
    
    func setPreferredDomain(_ domain: NetworkingDomain) {
        self.domain = domain
    }
}
