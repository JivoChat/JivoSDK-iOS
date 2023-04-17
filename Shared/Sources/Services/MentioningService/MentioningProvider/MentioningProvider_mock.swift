//
//  MentioningProviderMock.swift
//  App
//
//  Created by Stan Potemkin on 09.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif
@testable import Jivo

class MentioningProviderMock: IMentioningProvider {
    let agents: [JVAgent]
    
    init(agents: [JVAgent]) {
        self.agents = agents
    }
    
    func retrieveAgentName(forID ID: Int, generateDefault: Bool) -> String? {
        return agents.first(where: { $0.m_id == ID })?.m_display_name
    }
}
