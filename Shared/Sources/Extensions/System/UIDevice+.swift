//
//  UIDeviceExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 21/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
    var jv_isPhone: Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return true
        }
        else {
            return false
        }
    }
    
    var jv_modelID: String {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        if ["i386", "x86_64", "arm64"].contains(identifier) {
            return "Simulator"
        }
        else {
            return identifier
        }
    }
    
    var jv_isSimulator: Bool {
        return (jv_modelID == "Simulator")
    }
    
    func jv_isJailbroken() -> Bool {
        if jv_isSimulator {
            return false
        }
        
        let systemPaths: [String] = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/usr/bin/ssh",
            "/private/var/lib/apt",
            "/usr/bin/ssh"
        ]
        
        for path in systemPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
            
            if let file = fopen(path, "r") {
                fclose(file)
                return true
            }
        }
        
        do {
            let path = "/private/jailbreak." + UUID().uuidString
            try UUID().uuidString.write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        }
        catch {
            return false
        }
    }
}
