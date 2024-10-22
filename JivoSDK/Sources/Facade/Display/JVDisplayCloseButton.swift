//
//  JVDisplayCloseButton.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Close Button look
 */
public enum JVDisplayCloseButton: String, CaseIterable {
    /// No symbol
    case omit
    
    /// Back symbol, like "<"
    case back
    
    /// Cross symbol, like "X"
    case dismiss
}
