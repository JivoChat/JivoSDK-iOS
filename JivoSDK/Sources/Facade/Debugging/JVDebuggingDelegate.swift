//
//  JVDebuggingDelegate.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Interface to control debugging process,
 relates to `Jivo.debugging` namespace
 */
@objc(JVDebuggingDelegate)
public protocol JVDebuggingDelegate {
    /**
     Called when SDK is going to log event,
     here you are able to replace the standard behavior with your own implementation
     */
    func jivoDebugging(catchEvent: Jivo, text: String) -> JVDebuggingOriginalCatchBehavior
}
