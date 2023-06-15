//
//  JVClientProactiveRule+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension JVClientProactiveRule {
    var agent: JVAgent? {
        return m_agent
    }
    
    var date: Date {
        return m_date ?? Date()
    }
    
    var text: String {
        return m_text.jv_orEmpty
    }
}
