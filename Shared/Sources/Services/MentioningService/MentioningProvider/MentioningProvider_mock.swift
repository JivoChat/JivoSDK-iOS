//
//  MentioningProviderMock.swift
//  App
//
//  Created by Stan Potemkin on 09.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
@testable import App

class MentioningProviderMock: IMentioningProvider {
    let agents: [AgentEntity]
    
    init(agents: [AgentEntity]) {
        self.agents = agents
    }
    
    func retrieveAgentName(forID ID: Int, generateDefault: Bool) -> String? {
        return agents.first(where: { $0.m_id == ID })?.m_display_name
    }
}
