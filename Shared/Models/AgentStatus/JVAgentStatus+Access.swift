//
//  JVAgentStatus+Access.swift
//  App
//
//  Created by Stan Potemkin on 22.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension JVAgentStatus {
    var statusID: Int {
        return Int(m_id)
    }
    
    var title: String {
        return m_title.jv_orEmpty
    }
    
    var emoji: String {
        return m_emoji.jv_orEmpty.jv_convertToEmojis()
    }
    
    var position: Int {
        return Int(m_position)
    }
}
