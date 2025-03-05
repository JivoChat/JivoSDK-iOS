//
//  BundleExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 14/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

extension Bundle {
    struct InfoKey {
        static let identifier = kCFBundleIdentifierKey as String
        static let shortVersion = "CFBundleShortVersionString"
        static let version = "CFBundleVersion"
        static let name = "CFBundleName"
        static let displayName = "CFBundleDisplayName"
        static let packageVersion = "JVPackageVersion"
        private init() {}
    }
}

extension Bundle {
    var jv_ID: String? {
        return infoDictionary?[InfoKey.identifier] as? String
    }
    
    var jv_name: String? {
        return (infoDictionary?[InfoKey.displayName] ?? infoDictionary?[InfoKey.name]) as? String
    }
}

fileprivate var f_foundResourcesBundle: Bundle?
extension Bundle {
    static var jv_resourcesBundle: Bundle {
        if let bundle = f_foundResourcesBundle {
            return bundle
        }
        
        for subpath in Bundle.main.paths(forResourcesOfType: "bundle", inDirectory: nil) {
            let subname = (subpath as NSString).lastPathComponent
            guard subname.lowercased().contains("jivo") else {
                continue
            }
            
            if let bundle = Bundle(path: subpath) {
                f_foundResourcesBundle = bundle
                return bundle
            }
        }
        
        return Bundle.main
    }
    
    func jv_findDatabaseScheme(basename: String) -> URL? {
        if let fileUrl = url(forResource: basename, withExtension: "momd") {
            return fileUrl
        }
        
        for path in paths(forResourcesOfType: "omo", inDirectory: nil) {
            guard path.contains(basename) else {
                continue
            }
            
            return URL(fileURLWithPath: path) 
        }
        
        for path in Bundle.jv_resourcesBundle.paths(forResourcesOfType: "omo", inDirectory: nil) {
            guard path.contains(basename) else {
                continue
            }
            
            return URL(fileURLWithPath: path) 
        }
        
        return nil
    }
}

extension Bundle {
    enum VersionFormat {
        case marketingShort // "1.2.3"
        case marketingFull // "1.2.3 build 1234"
        case buildNumber // "1234"
        case semanticFull // "1.2.3+build.1234"
        case package // for calls from within JivoSDK
    }
    
    func jv_formatVersion(_ format: VersionFormat) -> String {
        let version = read(key: InfoKey.shortVersion, fallback: "0")
        let build = read(key: InfoKey.version, fallback: "0")
        
        switch format {
        case .marketingShort:
            return version
        case .marketingFull:
            return "\(version) build \(build)"
        case .buildNumber:
            return build
        case .semanticFull:
            return "\(version)+build.\(build)"
        case .package:
            return read(key: InfoKey.packageVersion, fallback: version)
        }
    }
    
    private func read(key: String, fallback: String) -> String {
        if let value = infoDictionary?[key] as? String {
            return value
        }
        else {
            return fallback
        }
    }
}
