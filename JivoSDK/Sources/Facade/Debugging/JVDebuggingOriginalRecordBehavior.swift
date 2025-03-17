//
//  JVDebuggingOriginalRecordBehavior.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 SDK behavior for recording entries
 */
public enum JVDebuggingOriginalRecordBehavior: String, CaseIterable {
    /// Store entries within internal SDK cache, as well 
    case store
    
    /// Ignore entries, prevent them from being stored
    case ignore
}
