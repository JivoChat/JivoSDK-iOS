//
//  ProcessInfo+.swift
//  App
//
//  Created by Stan Potemkin on 12.10.2024.
//

import Foundation

fileprivate let f_argumantal_prefix = "--host="

extension ProcessInfo {
    func jv_detectHostArgument() -> String? {
        if let arg = arguments.first(where: {$0.hasPrefix(f_argumantal_prefix)}) {
            return String(arg.dropFirst(f_argumantal_prefix.count))
        }
        else {
            return nil
        }
    }
}
