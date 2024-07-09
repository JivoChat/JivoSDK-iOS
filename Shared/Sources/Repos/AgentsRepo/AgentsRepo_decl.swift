//
//  AgentsRepoDecl.swift
//  App
//
//  Created by Stan Potemkin on 09.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

protocol IAgentsRepo: AnyObject {
    func retrieve(id: Int, lookup: AgentRepoRetrievalLookup) -> AgentEntity?
    func retrieveAll(listing: AgentRepoRetrievalListing) -> [AgentEntity]
    func updateDraft(id: Int, currentText: String?)
}
