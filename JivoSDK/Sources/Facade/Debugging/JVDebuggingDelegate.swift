//
//  JVDebuggingDelegate.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Acts like feedback from ``Jivo.debugging`` namespace
 */
@objc(JVDebuggingDelegate)
public protocol JVDebuggingDelegate {
    /**
     Called when JivoSDK wants to log a message,
     you are able to replace the standard way with your own implementation
     */
    func jivoDebugging(catchEvent: Jivo, text: String) -> JVDebuggingOriginalCatchBehavior
}
