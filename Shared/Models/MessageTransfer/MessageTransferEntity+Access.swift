//
//  MessageTransferEntity+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension MessageTransferEntity {
    var agentID: Int {
        return Int(m_agent_id)
    }
    
    var comment: String? {
        return m_comment
    }
}
