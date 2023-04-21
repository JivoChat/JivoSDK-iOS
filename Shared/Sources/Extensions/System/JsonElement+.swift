//
//  FileManager+Extensions.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 19.02.2023.
//

import Foundation
import JMCodingKit

public extension JsonElement {
    init<T>(key: String, value: T?) {
        if let value = value {
            self.init([key: value])
        } else {
            self.init(Dictionary<String, T>())
        }
    }
}
