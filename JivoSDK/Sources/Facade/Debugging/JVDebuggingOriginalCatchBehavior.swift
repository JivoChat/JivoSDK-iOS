//
//  JVDebuggingOriginalCatchBehavior.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 What should SDK do with original event catching behavior
 */
@objc(JVDebuggingOriginalCatchBehavior)
public enum JVDebuggingOriginalCatchBehavior: Int {
    /// Log an event details
    case keep
    
    /// Ignore an event details
    case ignore
}
