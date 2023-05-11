//
//  DataExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 14/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import SwiftyNSException

extension Data {
    static func jv_with(string: String, encoding: String.Encoding) -> Data? {
        return string.data(using: encoding)
    }
    
    func jv_toHex() -> String {
        return map({ String(format: "%02x", $0) }).joined()
    }
    
    func jv_unarchive<T: NSObject & NSCoding>(type: T.Type) -> T? {
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: self)
        }
        catch {
            return nil
        }
    }
}
