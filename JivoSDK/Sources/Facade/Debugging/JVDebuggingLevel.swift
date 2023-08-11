//
//  JVDebuggingLevel.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Level of logging verbosity,
 relates to ``Jivo.debugging`` namespace
 */
@objc(JVDebuggingLevel)
public enum JVDebuggingLevel: Int {
    /// Capture nothing
    case silent
    
    /// Capture everything
    case full
}
