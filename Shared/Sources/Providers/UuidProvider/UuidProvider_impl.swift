//
//  UUIDProvider.swift
//  App
//
//  Created by Anton Karpushko on 02.09.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation


final class UUIDProvider: IUUIDProvider {
    private let bundle: Bundle
    private let userAgent: UUIDProviderUserAgent
    private let keychainDriver: IKeychainDriver
    private let installationIDPreference: IPreferencesAccessor

    private let launchUUID = UUID()
    
    init(bundle: Bundle, userAgent: UUIDProviderUserAgent, keychainDriver: IKeychainDriver, installationIDPreference: IPreferencesAccessor) {
        self.bundle = bundle
        self.userAgent = userAgent
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
    
    var userAgentBrief: String {
        switch userAgent {
        case .app:
            return userAgentBrief_pack(values: [
                userAgentBrief_packageInfo(name: "JivoApp-ios", version: Bundle.main.jv_version),
                userAgentBrief_surround(fields: [
                    "Mobile",
                    "Device" => userAgentBrief_deviceInfo(),
                    "Platform" => userAgentBrief_platformInfo()
                ]),
                "(iOS \(UIDevice.current.systemVersion))",
                "CFNetwork/\(userAgentBrief_networkingInfo())",
                "Darwin/\(userAgentBrief_darwinInfo())"
            ])
        case .sdk:
            return userAgentBrief_pack(values: [
                userAgentBrief_packageInfo(name: "JivoSDK-ios", version: bundle.jv_version),
                userAgentBrief_surround(fields: [
                    "Mobile",
                    "Device" => userAgentBrief_deviceInfo(),
                    "Platform" => userAgentBrief_platformInfo(),
                    "Host" => userAgentBrief_hostInfo(bundle: .main),
                    "Engine" => userAgentBrief_engineInfo(),
                    "rv:02"
                ]),
                "sdk/\(bundle.jv_version)",
                "(iOS \(UIDevice.current.systemVersion))",
                "CFNetwork/\(userAgentBrief_networkingInfo())",
                "Darwin/\(userAgentBrief_darwinInfo())"
            ])
        }
    }
    
    private func userAgentBrief_pack(values: [String]) -> String {
        let result = values.joined(separator: " ")
        return result
    }
    
    private func userAgentBrief_surround(fields: [String?]) -> String {
        let result = "(" + fields.jv_flatten().joined(separator: "; ") + ")"
        return result
    }
    
    private func userAgentBrief_packageInfo(name: String, version: String) -> String {
        return "\(name)/\(version)"
    }
    
    private func userAgentBrief_hostInfo(bundle: Bundle) -> String {
        if let name = bundle.jv_ID ?? bundle.jv_name {
            return userAgentBrief_packageInfo(name: name, version: bundle.jv_version)
        }
        else {
            return userAgentBrief_packageInfo(name: "unknown", version: "0")
        }
    }
    
    private func userAgentBrief_deviceInfo() -> String {
        if UIDevice.current.jv_isSimulator {
            return "simulator"
        }
        
        do {
            let source = UIDevice.current.jv_modelID.lowercased()
            let regex = try NSRegularExpression(pattern: "^(\\w+?)([\\d,.]+)$")
            
            guard let match = regex.firstMatch(in: source, range: NSRange(location: 0, length: source.count)),
                  let familyRange = Range(match.range(at: 1), in: source),
                  let modelRange = Range(match.range(at: 2), in: source)
            else {
                throw NSError()
            }
            
            let family = source[familyRange]
            let model = source[modelRange]
            return "\(family)/\(model)"
        }
        catch {
            return "unknown"
        }
    }
    
    private func userAgentBrief_platformInfo() -> String {
        let family = UIDevice.current.systemName
        let version = UIDevice.current.systemVersion
        return "\(family)/\(version)"
    }
    
    private func userAgentBrief_engineInfo() -> String? {
        if let _ = objc_getClass("FlutterEngine") {
            return "flutter"
        }
        else if let _ = objc_getClass("RCTBridge") {
            return "react-native"
        }
        else if let _ = objc_getClass("SharedBase"), let _ = objc_getClass("SharedNumber") {
            return "kotlin-mm"
        }
        else {
            return nil
        }
    }
    
    private func userAgentBrief_networkingInfo() -> String {
        guard let bundle = Bundle(identifier: "com.apple.CFNetwork"),
              let version = bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
        else {
            return "unknown"
        }
        
        return version
    }
    
    private func userAgentBrief_darwinInfo() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.release)
        let version = machineMirror.children.reduce(String()) { identifier, element in
            guard let value = element.value as? Int8,
                  value != 0
            else {
                return identifier
            }
            
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        if version.isEmpty {
            return "unknown"
        }
        else {
            return version
        }
    }
}

infix operator =>
fileprivate func => (key: String, value: String?) -> String? {
    if let value = value {
        return "\(key)=\(value)"
    }
    else {
        return nil
    }
}
