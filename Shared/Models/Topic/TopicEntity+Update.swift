//
//  TopicEntity+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension TopicEntity {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = Int64(m_id)
        }
        
        if let c = change as? JVTopicEmptyChange {
            m_id = c.id.jv_toInt64(.standard)
        }
        else if let c = change as? JVTopicGeneralChange {
            m_id = c.id.jv_toInt64(.standard)
            m_parent = c.parentId?.jv_valuable.flatMap { context.topic(for: $0, needsDefault: true) }
            m_title = c.title
            m_created_at = Date(timeIntervalSince1970: c.createdAt)
        }
    }
}

final class JVTopicEmptyChange: JVDatabaseModelChange {
    let id: Int

    override var primaryValue: Int {
        return id
    }
    
    required init(json: JsonElement) {
        preconditionFailure()
    }
    
    init(id: Int) {
        self.id = id
        super.init()
    }
}

final class JVTopicGeneralChange: JVDatabaseModelChange {
    let id: Int
    let parentId: Int?
    let title: String
    let createdAt: TimeInterval

    override var primaryValue: Int {
        return id
    }
    
    required init(json: JsonElement) {
        id = json["topic_id"].intValue
        parentId = json["parent_id"].int
        title = json["title"].stringValue
        createdAt = json["created_ts"].doubleValue
        super.init(json: json)
    }
}
