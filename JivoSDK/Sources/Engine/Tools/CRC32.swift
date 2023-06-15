//
//  CRC32.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 01.10.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

class CRC32 {
        
    static var table: [UInt32] = {
        (0...255).map { i -> UInt32 in
            (0..<8).reduce(UInt32(i), { c, _ in
                (c % 2 == 0) ? (c >> 1) : (0xEDB88320 ^ (c >> 1))
            })
        }
    }()
    
    static func encrypt(_ string: String) -> Int {
        let buffer: [UInt8] = Array(string.utf8)
        return Int(checksum(bytes: buffer))
    }

    private static func checksum(bytes: [UInt8]) -> UInt32 {
        return ~(bytes.reduce(~UInt32(0), { crc, byte in
            (crc >> 8) ^ table[(Int(crc) ^ Int(byte)) & 0xFF]
        }))
    }
}
