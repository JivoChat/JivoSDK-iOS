//
//  ArchiveHitItemEntity+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension ArchiveHitItemEntity {
    var agents: [AgentEntity] {
        if let allObjects = m_agents?.allObjects as? [AgentEntity] {
            return allObjects
        }
        else {
            return Array()
        }
    }
    
    var chat: ChatEntity? {
        return m_chat
    }
    
    var duration: TimeInterval {
        return TimeInterval(m_duration)
    }
}
