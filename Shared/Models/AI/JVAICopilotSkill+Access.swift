//
//  JVAICopilotSkill+Access.swift
//  App
//
//  Created by Julia Popova on 06.02.2024.
//

import Foundation

extension JVAICopilotSkill {
    var skillID: Int {
        return Int(m_id)
    }
    
    var skillName: String {
        return m_title.jv_orEmpty
    }
    
    var emoji: String {
        return m_emoji.jv_orEmpty.jv_convertToEmojis()
    }
}
