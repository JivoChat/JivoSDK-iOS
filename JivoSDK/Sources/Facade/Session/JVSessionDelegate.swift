//
//  JVSessionDelegate.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Acts like feedback from ``Jivo.session`` namespace
 */
@objc(JVSessionDelegate)
public protocol JVSessionDelegate {
    /**
     Here you can listen for unread counter updates
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter number:
     Actual number to take in account when updating your custom UI indicators
     */
    @objc(jivoSessionUpdateUnreadCounter:number:)
    func jivoSession(updateUnreadCounter sdk: Jivo, number: Int)
}
