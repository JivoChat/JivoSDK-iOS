//
//  JVCannedPhrase+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVCannedPhrase {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let change = change as? JVCannedPhraseGeneralChange {
            m_message = change.message
            m_message_hash_id = change.messageHashID
            m_total_score = change.totalScore.jv_toInt32(.standard)
            m_session_score = change.sessionScore.jv_toInt16(.standard)
            m_timestamp = Double(change.timestamp)
            m_was_deleted = change.isDeleted
        }
        else if let _ = change as? JVCannedPhraseFlushScoreChange {
            m_total_score += Int32(m_session_score)
            m_session_score = 0
        }
    }
}

final class JVCannedPhraseGeneralChange: JVDatabaseModelChange, Codable {
    var messageHashID: String
    var message: String
    var timestamp: Int
    var totalScore: Int
    var sessionScore: Int
    var isDeleted: Bool

    override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_message_hash_id", value: messageHashID)
    }
    
    public required init(json: JsonElement) {
        messageHashID = json["message_hash_id"].stringValue
        message = json["message"].stringValue
        timestamp = json["timestamp"].intValue
        totalScore = json["score"].intValue
        sessionScore = 0
        isDeleted = false
        super.init(json: json)
    }

    init(messageHashID: String,
                message: String,
                timestamp: Int,
                totalScore: Int,
                sessionScore: Int,
                isDeleted: Bool) {
        self.messageHashID = messageHashID
        self.message = message
        self.timestamp = timestamp
        self.totalScore = totalScore
        self.sessionScore = sessionScore
        self.isDeleted = isDeleted
        super.init()
    }
}

final class JVCannedPhraseFlushScoreChange: JVDatabaseModelChange {
}
