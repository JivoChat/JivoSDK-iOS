//
//  StaticAddressWrapper.swift
//  App
//
//  Created by Stan Potemkin on 19.02.2024.
//

import Foundation

@propertyWrapper
struct StaticAddressWrapper {
    var _placeholder: Int8 = 0
    
    var wrappedValue: UnsafeMutableRawPointer {
        mutating get {
            // This is "ok" only as long as the wrapped property appears
            // inside of something with a stable address (a global/static
            // variable or class property) and the pointer is never read or
            // written through, only used for its unique value
            return withUnsafeMutableBytes(of: &self) {
                return $0.baseAddress.unsafelyUnwrapped
            }
        }
    }
}
