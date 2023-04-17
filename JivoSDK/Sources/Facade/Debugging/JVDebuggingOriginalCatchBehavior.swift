//
//  JVDebuggingOriginalCatchBehavior.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Determine what JivoSDK should perform for logging event
 */
@objc(JVDebuggingOriginalCatchBehavior)
public enum JVDebuggingOriginalCatchBehavior: Int {
    /// Log an event details
    case keep
    
    /// Ignore an event details
    case ignore
}
