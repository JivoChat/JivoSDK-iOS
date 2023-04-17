//
//  MentioningServiceUnit.swift
//  App
//
//  Created by Stan Potemkin on 23.10.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import XCTest
@testable import JivoFoundation
@testable import Jivo

class MentioningServiceUnit: XCTestCase {
    private let sampleTextPlain = "There are @bob and @alice being mentioned @here"
    private let sampleTextMarkup = "There are <@1> and <@2> being mentioned <!here>"
    private let sampleNumberOfPersons = 2
    private let sampleCaretOutOfContext = 0
    private let sampleCaretWithinContext = 10
    private let sampleCaretFound = 13
    
    func test_extractPossibleQuery() {
        let (service, _) = constructTuple()
        
        switch service.extractPossibleQuery(text: sampleTextPlain, caret: nil) {
        case .outOfContext:
            XCTAssert(true)
        default:
            XCTAssert(false)
        }
        
        switch service.extractPossibleQuery(text: sampleTextPlain, caret: sampleCaretOutOfContext) {
        case .outOfContext:
            XCTAssert(true)
        default:
            XCTAssert(false)
        }
        
        switch service.extractPossibleQuery(text: sampleTextPlain, caret: 8) {
        case .outOfContext:
            XCTAssert(true)
        default:
            XCTAssert(false)
        }
        
        switch service.extractPossibleQuery(text: sampleTextPlain, caret: 9) {
        case .outOfContext:
            XCTAssert(true)
        default:
            XCTAssert(false)
        }
        
        switch service.extractPossibleQuery(text: sampleTextPlain, caret: sampleCaretWithinContext) {
        case .withinContext:
            XCTAssert(true)
        default:
            XCTAssert(false)
        }
        
        switch service.extractPossibleQuery(text: sampleTextPlain, caret: sampleCaretFound) {
        case .found("bob"):
            XCTAssert(true)
        default:
            XCTAssert(false)
        }
    }
    
    func test_detectMentionWhileTyping() {
        let (service, repo) = constructTuple()

        switch service.detectMentionWhileTyping(text: sampleTextPlain, caret: sampleCaretOutOfContext) {
        case .outOfContext:
            XCTAssert(true)
        default:
            XCTAssert(false)
        }
        
        switch service.detectMentionWhileTyping(text: sampleTextPlain, caret: sampleCaretWithinContext) {
        case .found(let items):
            XCTAssertEqual(
                items
                    .compactMap(\.storedAgent)
                    .map(\.m_display_name),
                repo
                    .retrieveAll(listing: .exceptMe)
                    .map(\.m_display_name))
        default:
            XCTAssert(false)
        }
        
        switch service.detectMentionWhileTyping(text: sampleTextPlain, caret: sampleCaretFound) {
        case .found(let items):
            XCTAssertEqual(
                items
                    .compactMap(\.storedAgent)
                    .map(\.m_display_name),
                ["bob"])
        default:
            XCTAssert(false)
        }
    }
    
    func test_convertPlainToMarkup() {
        let (service, _) = constructTuple()

        XCTAssertEqual(
            service.convertPlainToMarkup(text: sampleTextPlain),
            sampleTextMarkup)
    }
    
    func test_convertMarkupToPlain() {
        let (service, _) = constructTuple()

        XCTAssertEqual(
            service.convertMarkupToPlain(text: sampleTextMarkup),
            sampleTextPlain)
    }
    
    func test_detectMissingAgents() {
        let (service, _) = constructTuple()

        let chat = JVChatMock()
        chat.m_is_group = false
        
        XCTAssertEqual(
            service.detectMissingAgents(markup: sampleTextMarkup, chat: chat),
            Array())

        let group = JVChatMock()
        group.m_is_group = true
        
        XCTAssertEqual(
            service.detectMissingAgents(markup: sampleTextMarkup, chat: group).count,
            sampleNumberOfPersons)
    }
}

fileprivate func constructTuple() -> (IMentioningService, IAgentsRepo) {
    let bob = JVAgentMock()
    bob.m_id = 1
    bob.m_email = "bob@example.com"
    bob.m_display_name = "bob"
    
    let alice = JVAgentMock()
    alice.m_id = 2
    alice.m_email = "alice@example.com"
    alice.m_display_name = "alice"
    
    let tom = JVAgentMock()
    tom.m_id = 3
    tom.m_email = "tom@example.com"
    tom.m_display_name = "tom"
    
    let agents = [bob, alice, tom]
    let provider = MentioningProviderMock(agents: agents)
    let repo = AgentsRepoMock(agents: agents)
    let service = MentioningService(rosterContext: provider, agentsRepo: repo)
    
    return (service, repo)
}

fileprivate extension MentionsItem {
    var storedAgent: JVAgent? {
        switch self {
        case .agent(let agent):
            return agent
        default:
            return nil
        }
    }
}
