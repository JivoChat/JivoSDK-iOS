//
//  JVDebuggingArchiveStatus.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Determines how logs archiving operation was completed
 */
@objc(JVDebuggingArchiveStatus)
public enum JVDebuggingArchiveStatus: Int {
    /// Archive is ready
    case success
    
    /// Failed accessing
    case failedAccessing
    
    /// Failed archiving
    case failedPreparing
}
