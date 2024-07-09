//
//  AgentsRepoMock.swift
//  App
//
//  Created by Stan Potemkin on 09.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
@testable import App

class AgentsRepoMock: IAgentsRepo {
    let agents: [AgentEntity]
    
    init(agents: [AgentEntity]) {
        self.agents = agents
    }
    
    func retrieve(id: Int, lookup: AgentRepoRetrievalLookup) -> AgentEntity? {
        return agents.first(where: { $0.m_id == id })
    }
    
    func retrieveAll(listing: AgentRepoRetrievalListing) -> [AgentEntity] {
        return agents
    }
    
    func updateDraft(id: Int, currentText: String?) {
    }
}
