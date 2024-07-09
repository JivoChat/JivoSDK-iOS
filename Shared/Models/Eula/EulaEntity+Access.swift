//
//  EulaEntity+Access.swift
//  App
//
//  Created by Yulia Popova on 29.06.2023.
//

import Foundation

extension EulaEntity {
    static let openAILicenseName = "AI_MODULE_OPENAI"
    static let sberAILicenseName = "AI_MODULE_SBER"
    
    var module: String {
        return m_module.jv_orEmpty
    }
    
    var agentID: Int {
        return Int(m_agent_id)
    }
}
