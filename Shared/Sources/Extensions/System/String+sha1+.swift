//
//  String+SHA1.swift
//  JMShared
//
//  Created by Yulia on 10.11.2022.
//

import Foundation
import CommonCrypto

extension String {
    func jv_sha1() -> [UInt8] {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        
        return digest
    }
    
    func jv_sha256() -> [UInt8] {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
        }
        
        return digest
    }
    
    func jv_sha512() -> [UInt8] {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0,  count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA512($0.baseAddress, CC_LONG(data.count), &digest)
        }
        
        return digest
    }
}
