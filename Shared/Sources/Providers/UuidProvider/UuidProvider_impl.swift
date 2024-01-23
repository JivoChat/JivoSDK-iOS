//
//  UUIDProvider.swift
//  App
//
//  Created by Anton Karpushko on 02.09.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation
import PushKit

final class UUIDProvider: IUUIDProvider {
    private let bundle: Bundle
    private let package: UuidSubUserAgentPackage
    private let keychainDriver: IKeychainDriver
    private let installationIDPreference: IPreferencesAccessor

    private let launchUUID = UUID()
    
    init(bundle: Bundle, package: UuidSubUserAgentPackage, keychainDriver: IKeychainDriver, installationIDPreference: IPreferencesAccessor) {
        self.bundle = bundle
        self.package = package
        self.keychainDriver = keychainDriver
        self.installationIDPreference = installationIDPreference
    }
    
    var currentDeviceID: String {
        if let value = keychainDriver.retrieveAccessor(forToken: .deviceID).string {
            return value
        }
        else {
            let value = UUID().uuidString.lowercased()
            keychainDriver.retrieveAccessor(forToken: .deviceID).string = value
            return value
        }
    }
    
    var currentInstallationID: String {
        if let value = installationIDPreference.string {
            return value
        }
        else {
            let value = UUID().uuidString.lowercased()
            installationIDPreference.string = value
            return value
        }
    }

    var currentLaunchID: String {
        return launchUUID.uuidString.lowercased()
    }
    
    @AtomicMut
    private var userAgentBrief_cache = [Bundle: String]()
    var userAgentBrief: String {
        if let result = $userAgentBrief_cache.mutate({ $0[bundle] }) {
            return result
        }
        else {
            let result = UuidSubUserAgentGenerator(bundle: bundle, package: package).generate()
            $userAgentBrief_cache.mutate { $0[bundle] = result }
            return result
        }
    }
}
