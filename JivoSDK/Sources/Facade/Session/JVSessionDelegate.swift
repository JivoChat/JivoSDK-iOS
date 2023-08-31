//
//  JVSessionDelegate.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Interface to handle session events,
 relates to ``Jivo.session`` namespace
 */
@objc(JVSessionDelegate)
public protocol JVSessionDelegate {
    /**
     Called when unread counter changes
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter number:
     Actual number to take in account when updating your custom UI indicators
     */
    @objc(jivoSessionUpdateUnreadCounter:number:)
    func jivoSession(updateUnreadCounter sdk: Jivo, number: Int)
}
