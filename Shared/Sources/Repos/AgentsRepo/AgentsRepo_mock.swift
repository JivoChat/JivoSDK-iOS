//
//  AgentsRepoMock.swift
//  App
//
//  Created by Stan Potemkin on 09.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
@testable import Jivo

class AgentsRepoMock: IAgentsRepo {
    let agents: [JVAgent]
    
    init(agents: [JVAgent]) {
        self.agents = agents
    }
    
    func retrieve(id: Int, lookup: AgentRepoRetrievalLookup) -> JVAgent? {
        return agents.first(where: { $0.m_id == id })
    }
    
    func retrieveAll(listing: AgentRepoRetrievalListing) -> [JVAgent] {
        return agents
    }
}
