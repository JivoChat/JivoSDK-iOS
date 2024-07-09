//
//  CannedPhraseEntity+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension CannedPhraseEntity {
    var id: String {
        return m_id.jv_orEmpty
    }
    
    var message: String {
        return m_message.jv_orEmpty
    }
    
    var messageHashID: String {
        return m_message_hash_id.jv_orEmpty
    }
    
    var timestamp: Int {
        return Int(m_timestamp)
    }
    
    var sessionScore: Int {
        return Int(m_session_score)
    }
    
    var totalScore: Int {
        return Int(m_total_score)
    }
    
    var wasDeleted: Bool {
        return m_was_deleted
    }
}
