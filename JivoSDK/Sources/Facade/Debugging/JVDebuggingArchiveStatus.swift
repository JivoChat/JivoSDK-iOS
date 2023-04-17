//
//  JVDebuggingArchiveStatus.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

@objc(JVDebuggingArchiveStatus)
public enum JVDebuggingArchiveStatus: Int {
    /// Archive is ready
    case success
    
    /// Failed accessing
    case failedAccessing
    
    /// Failed archiving
    case failedPreparing
}
