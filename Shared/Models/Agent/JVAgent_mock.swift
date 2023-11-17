//
//  JVAgentMock.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 09.03.2023.
//

import Foundation
@testable import App

final class JVAgentMock: JVAgent {
    override var m_id: Int64 {
        get { takeFromCache(key: #function, defaultValue: Int64.zero) }
        set { putIntoCache(key: #function, value: newValue) }
    }
    
    override var m_email: String? {
        get { takeFromCache(key: #function, defaultValue: String?.none) }
        set { putIntoCache(key: #function, value: newValue) }
    }
    
    override var m_display_name: String? {
        get { takeFromCache(key: #function, defaultValue: String?.none) }
        set { putIntoCache(key: #function, value: newValue) }
    }
}
