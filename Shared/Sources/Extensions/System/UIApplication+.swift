//
//  UIApplicationExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 27/09/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    func jv_findActiveWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            return connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .compactMap(\.keyWindow)
                .first
        }
        else {
            return windows.first
        }
    }
    
    var jv_isActive: Bool {
        switch applicationState {
        case .active: return true
        case .inactive: return false
        case .background: return false
        @unknown default: return false
        }
    }
    
    func jv_discardCachedLaunchScreen() {
        let path = NSHomeDirectory() + "/Library/SplashBoard"
        try? FileManager.default.removeItem(atPath: path)
    }
}

extension UIApplication {
    struct ApnsEnvironment {
        let shouldUseSandbox: Bool
        static let development = Self.init(shouldUseSandbox: true)
        static let production = Self.init(shouldUseSandbox: false)
        static let unknown = Self.init(shouldUseSandbox: false)
    }
    
    func jv_detectApnsEnvironment() -> ApnsEnvironment {
        if UIDevice.current.jv_isSimulator {
            return .development
        }
        
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let content = try? String(contentsOf: url, encoding: .ascii)
        else {
            return .unknown
        }
        
        let scanner = ScannerTool(source: content)
        scanner.scan(over: "<key>aps-environment</key>")
        scanner.scan(over: "<string>")
        
        switch scanner.scan(till: "</string>") {
        case "development":
            return .development
        case "production":
            return .production
        default:
            return .unknown
        }
    }
}

extension UIApplication.State {
    var jv_description: String {
        switch self {
        case .active: return "active"
        case .background: return "background"
        case .inactive: return "inactive"
        @unknown default: return String(describing: self)
        }
    }
}
