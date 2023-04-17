//
//  AgentsRepo.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 23.10.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

enum AgentRepoRetrievalLookup {
    case storedOnly
    case storedOrCreated
}

enum AgentRepoRetrievalListing {
    case everyone
    case exceptMe
}

final class AgentsRepo: IAgentsRepo {
    private let databaseDriver: JVIDatabaseDriver
    
    init(databaseDriver: JVIDatabaseDriver) {
        self.databaseDriver = databaseDriver
    }
    
    func retrieve(id: Int, lookup: AgentRepoRetrievalLookup) -> JVAgent? {
        switch lookup {
        case .storedOnly:
            return databaseDriver.agent(for: id, provideDefault: false)
        case .storedOrCreated:
            return databaseDriver.agent(for: id, provideDefault: true)
        }
    }
    
    func retrieveAll(listing: AgentRepoRetrievalListing) -> [JVAgent] {
        switch listing {
        case .everyone:
            return databaseDriver.agents(withMe: true)
        case .exceptMe:
            return databaseDriver.agents(withMe: false)
        }
    }
}
