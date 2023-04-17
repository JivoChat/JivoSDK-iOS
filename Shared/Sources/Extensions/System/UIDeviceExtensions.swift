//
//  UIDeviceExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 21/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

public extension UIDevice {
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

        if ["i386", "x86_64"].contains(identifier) {
            return "Simulator"
        }
        else {
            return identifier
        }
    }
    
    var jv_isSimulator: Bool {
        return (jv_modelID == "Simulator")
    }
}
