//
//  JVChatMock.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 09.03.2023.
//

import Foundation

final class JVChatMock: JVChat {
    override var m_is_group: Bool {
        get { takeFromCache(key: #function, defaultValue: false) }
        set { putIntoCache(key: #function, value: newValue) }
    }
    
    override var m_attendees: NSSet? {
        get { takeFromCache(key: #function, defaultValue: NSSet?.none) }
        set { putIntoCache(key: #function, value: newValue) }
    }
}
