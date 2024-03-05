//
//  UuidSubUserAgentGenerator_impl.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 24.04.2023.
//

import Foundation

final class UuidSubUserAgentGenerator: IUuidSubUserAgentGenerator {
    private let bundle: Bundle
    private let package: UuidSubUserAgentPackage
    
    init(bundle: Bundle, package: UuidSubUserAgentPackage) {
        self.bundle = bundle
        self.package = package
    }
    
    func generate() -> String {
        switch package {
        case .app:
            return enumerate(values: [
                collectPackageInfo(name: "JivoApp-ios", version: bundle.jv_formatVersion(.semanticFull)),
                surround(fields: [
                    "Mobile",
                    "Device" => collectDeviceInfo(),
                    "Platform" => collectPlatformInfo(),
                    "Environment" => collectEnvironmentInfo()
                ]),
                "(iOS \(UIDevice.current.systemVersion))",
                "CFNetwork/\(collectNetworkingInfo())",
                "Darwin/\(collectDarwinInfo())"
            ])
        case .sdk:
            return enumerate(values: [
                collectPackageInfo(name: "JivoSDK-ios", version: bundle.jv_formatVersion(.package)),
                surround(fields: [
                    "Mobile",
                    "Device" => collectDeviceInfo(),
                    "Platform" => collectPlatformInfo(),
                    "Host" => collectHostInfo(),
                    "Environment" => collectEnvironmentInfo(),
                    "Engine" => collectEngineInfo()
                ]),
                "sdk/\(bundle.jv_formatVersion(.marketingShort))",
                "(iOS \(UIDevice.current.systemVersion))",
                "CFNetwork/\(collectNetworkingInfo())",
                "Darwin/\(collectDarwinInfo())"
            ])
        }
    }
    
    private func enumerate(values: [String]) -> String {
        let result = values.joined(separator: " ")
        return result
    }
    
    private func surround(fields: [String?]) -> String {
        let result = "(" + fields.jv_flatten().joined(separator: "; ") + ")"
        return result
    }
    
    private func collectPackageInfo(name: String, version: String) -> String {
        return "\(name)/\(version)"
    }
    
    private func collectDeviceInfo() -> String {
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
    
    private func collectPlatformInfo() -> String {
        let family = UIDevice.current.systemName.lowercased().replacingOccurrences(of: "ipados", with: "ios")
        let version = UIDevice.current.systemVersion
        return "\(family)/\(version)"
    }
    
    private func collectHostInfo() -> String {
        let bundle = Bundle.main
        
        if let name = bundle.jv_ID ?? bundle.jv_name {
            return collectPackageInfo(name: name, version: bundle.jv_formatVersion(.marketingShort))
        }
        else {
            return collectPackageInfo(name: "unknown", version: "0")
        }
    }
    
    private func collectEnvironmentInfo() -> String {
        enum _Environment: String {
            case development
            case production
            func format(details: String) -> String { rawValue + "/" + details }
        }

        func _detectUsingProvision() -> String? {
            guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
                  let provisioning = try? String(contentsOf: url, encoding: .isoLatin1)
            else {
                return nil
            }
            
            let scanner = ScannerTool(source: provisioning)
            scanner.scan(till: _ProvisionTokens.apsEnvironment.rawValue)
            scanner.scan(over: _ProvisionTokens.stringBegin.rawValue)
            
            guard let alias = scanner.scan(till: _ProvisionTokens.stringEnd.rawValue)
            else {
                return nil
            }
            
            if let environment = _Environment(rawValue: alias) {
                return environment.format(details: "provision")
            }
            else {
                return nil
            }
        }
        
        func _detectUsingReceipt() -> String? {
            guard let url = bundle.appStoreReceiptURL
            else {
                return nil
            }
            
            if url.lastPathComponent == "sandboxReceipt" {
                return _Environment.production.format(details: "testflight")
            }
            else if url.lastPathComponent == "receipt" {
                return _Environment.production.format(details: "appstore")
            }
            else {
                return _Environment.production.format(details: url.lastPathComponent)
            }
        }
        
        if UIDevice.current.jv_isSimulator {
            return _Environment.development.format(details: "simulator")
        }
        else if let info = _detectUsingProvision() {
            return info
        }
        else if let info = _detectUsingReceipt() {
            return info
        }
        else {
            return _Environment.production.format(details: "unknown")
        }
    }
    
    private func collectEngineInfo() -> String? {
        if let _ = objc_getClass("FlutterEngine") {
            return "flutter"
        }
        else if let _ = objc_getClass("RCTBridge") {
            return "reactnative"
        }
        else if let _ = objc_getClass("SharedBase"), let _ = objc_getClass("SharedNumber") {
            return "kmp"
        }
        else {
            return nil
        }
    }
    
    private func collectNetworkingInfo() -> String {
        guard let bundle = Bundle(identifier: "com.apple.CFNetwork"),
              let version = bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
        else {
            return "unknown"
        }
        
        return version
    }
    
    private func collectDarwinInfo() -> String {
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

fileprivate enum _ProvisionTokens: String {
    case apsEnvironment = "aps-environment"
    case stringBegin = "<string>"
    case stringEnd = "</string>"
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
