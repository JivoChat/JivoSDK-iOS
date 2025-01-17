//
//  ObfuscateTool_impl.swift
//
//  Created by Stan Potemkin on 24.04.2023.
//

import Foundation

@dynamicMemberLookup
final class ObfuscateTool: IObfuscateTool {
    private var buffer = String()
    
    static func begin() -> Self {
        return Self.init()
    }
    
    private init() {
    }
    
    subscript(dynamicMember member: String) -> Self {
        buffer.append(member.replacingOccurrences(of: "_", with: ""))
        return self
    }
    
    var dot: Self {
        return self[dynamicMember: "."]
    }
    
    var dash: Self {
        return self[dynamicMember: "-"]
    }
    
    var underscore: Self {
        return self[dynamicMember: "_"]
    }
    
    func commit() -> String {
        return buffer
    }
}
