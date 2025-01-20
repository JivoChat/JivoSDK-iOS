//
//  NetworkingContext.swift
//  App
//
//  Created by Stan Potemkin on 07.04.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

final class NetworkingContext: INetworkingContext {
    private let defaultHost: String?
    let localeProvider: JVILocaleProvider
    
    private let mGlobalDomain = "jivosite.com"
    private let mRussianDomain = "jivo.ru"
    private let settingsTypeKey = "jivo:connectivity.connection_type"
    private let settingsHostKey = "jivo:connectivity.connection_host"

    private let argumentalHost: String?
    private var domain = NetworkingDomain.auto
    
    init(defaultHost: String?, localeProvider: JVILocaleProvider) {
        self.defaultHost = defaultHost?.jv_valuable
        self.localeProvider = localeProvider
        
        argumentalHost = ProcessInfo.processInfo.jv_detectHostArgument()
    }
    
    var primaryDomain: String {
        if let host = UserDefaults.standard.string(forKey: settingsHostKey)?.jv_valuable {
            return host
        }
        
        if let host = argumentalHost {
            if host == "localhost" {
                return host
            }
            else if let _ = host.firstIndex(of: Character(.jv_dot)) {
                return host
            }
            else {
                return "\(host).dev.\(mGlobalDomain)"
            }
        }
        
        if let defaultHost {
            return defaultHost
        }
        
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
        
        switch UserDefaults.standard.string(forKey: settingsTypeKey) {
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
