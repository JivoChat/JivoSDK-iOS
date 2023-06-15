//
//  JVDisplayCloseButton.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Choose the preferred Close Button look
 */
@objc(JVDisplayCloseButton)
public enum JVDisplayCloseButton: Int {
    /// No symbol
    case omit
    
    /// Back symbol, like "<"
    case back
    
    /// Cross symbol, like "X"
    case dismiss
}
