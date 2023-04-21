//
//  JVCannedPhrase+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension JVCannedPhrase {
    public var id: String {
        return m_id.jv_orEmpty
    }
    
    public var message: String {
        return m_message.jv_orEmpty
    }
    
    public var messageHashID: String {
        return m_message_hash_id.jv_orEmpty
    }
    
    public var timestamp: Int {
        return Int(m_timestamp)
    }
    
    public var sessionScore: Int {
        return Int(m_session_score)
    }
    
    public var totalScore: Int {
        return Int(m_total_score)
    }
    
    public var wasDeleted: Bool {
        return m_was_deleted
    }
}
