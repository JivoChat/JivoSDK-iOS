//
//  Bool+Extensions.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 18.10.2021.
//

import Foundation

extension Bool {
    mutating func getAndDisable() -> Bool {
        defer { self = false }
        return self
    }
}
