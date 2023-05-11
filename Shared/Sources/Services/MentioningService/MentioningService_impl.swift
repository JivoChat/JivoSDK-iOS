//
//  MentioningService.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 19.02.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation


/// What is mentioned: specific agent or any group
enum MentionsItem {
    case agent(JVAgent)
    case broadcast(String)
}

/// The current state of cursor position within the input field
enum MentionsDetection<T> {
    case outOfContext // outside of any mentioning
    case withinContext // just '@' was typed, but nothing else
    case notFound // '@' with query was typed, but nothing was found for that query
    case found(T) // '@' with query was typed, and something was found for that query
}

// At the moment, the only broadcast identifier is 'here', so let's hard-code it
fileprivate let broadcastIdentifiers = ["here", "group"]

extension CharacterSet {
    // Allow alphabet, digits, dot and plus, to act as query after '@' symbol
    static let mentioningQuery = CharacterSet(charactersIn: ".-+").union(.alphanumerics).subtracting(.variativeSelectors)
    // Allow all queryable symbols above, plus '@' symbol, to act as entire mention block
    static let mentioningBlock = CharacterSet(charactersIn: "@").union(.mentioningQuery)
    // Gaps those are not for parsing
    static let mentioningGap = CharacterSet.mentioningBlock.inverted
    // Unicode special controls: variative selectors
    fileprivate static let variativeSelectors = CharacterSet(charactersIn: "\u{FE00}"..."\u{FE0F}")
}

final class MentioningService: IMentioningService {
    private let rosterContext: IMentioningProvider
    private let agentsRepo: IAgentsRepo
    
    init(rosterContext: IMentioningProvider, agentsRepo: IAgentsRepo) {
        self.rosterContext = rosterContext
        self.agentsRepo = agentsRepo
    }
    
    func extractPossibleQuery(text: String?, caret: Int?) -> MentionsDetection<String> {
        // No text, no caret?
        guard let text = text, let caret = caret else {
            return .outOfContext
        }
        
        // An empty text preceding the caret, oops
        let observableSlice = text.jv_substringTo(index: caret)
        guard !(observableSlice.isEmpty) else {
            return .outOfContext
        }
        
        // The symbol in front of caret must not be a whitespace or a newlne
        let trail = String(observableSlice.suffix(1))
        if !(trail.isEmpty), trail.jv_contains(only: .mentioningGap) {
            return .outOfContext
        }
        
        // Now, extract all mentionable symbols in front of caret
        let givenSlice = observableSlice.trimmingCharacters(in: .mentioningGap)
        let givenWords = (givenSlice as NSString).components(separatedBy: .mentioningGap)
        
        // Make sure it is mention, so it starts with single '@'
        guard let mention = givenWords.last, mention.hasPrefix("@"), !mention.hasPrefix("@@") else {
            return .outOfContext
        }
        
        // Exctract the query itself, it means everything but '@'
        let query = mention.jv_substringFrom(index: 1)
        guard !(query.isEmpty) else {
            return .withinContext
        }
        
        // Check the query contains only allowed symbols for queries
        let enteredSymbols = CharacterSet(charactersIn: query)
        if enteredSymbols.subtracting(.mentioningQuery).isEmpty {
            return .found(query)
        }
        else {
            return .outOfContext
        }
    }
    
    func detectMentionWhileTyping(text: String?, caret: Int?) -> MentionsDetection<[MentionsItem]> {
        // Detect the query for the provided input
        switch extractPossibleQuery(text: text, caret: caret) {
        case .outOfContext:
            return .outOfContext
            
        case .withinContext:
            // Just '@' was typed, so get all possible options
            return .found(findAllItems())
            
        case .notFound:
            return .notFound
            
        case .found(let query):
            // Valid query was typed, so find only options for that query
            let foundItems = findItemsUsingPartialSearch(query: query)
            return foundItems.isEmpty ? .notFound : .found(foundItems)
        }
    }
    
    func convertPlainToMarkup(text: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: #"\B(@([a-zA-Z0-9\.\+]+))\b"#, options: [])
            let range = NSMakeRange(0, text.utf16.count)
            let matches = regex.matches(in: text, options: [], range: range)
            
            var result = NSString(string: text)
            for match in matches.reversed() {
                let query = result.substring(with: match.range(at: 2))
                if let item = findItemUsingIdentifyingSearch(query: query) {
                    switch item {
                    case .agent(let agent):
                        result = result.replacingCharacters(in: match.range(at: 1), with: "<@\(agent.ID)>") as NSString
                    case .broadcast(let identifier):
                        result = result.replacingCharacters(in: match.range(at: 1), with: "<!\(identifier)>") as NSString
                    }
                }
            }
            
            return result as String
        }
        catch {
            return text
        }
    }
    
    func convertMarkupToPlain(text: String) -> String {
        var result = NSString(string: text)

        do {
            let regex = try NSRegularExpression(pattern: #"<@(\d+)>"#, options: [])
            let matches = regex.matches(in: result as String, options: [], range: NSMakeRange(0, result.length))
            
            for match in matches.reversed() {
                let identifier = result.substring(with: match.range(at: 1)).jv_toInt()
                
                if let name = rosterContext.retrieveAgentName(forID: identifier, generateDefault: false) {
                    result = result.replacingCharacters(in: match.range, with: "@\(name)") as NSString
                }
                else {
                    result = result.replacingCharacters(in: match.range, with: "@\(identifier)") as NSString
                }
            }
        }
        catch {
        }
        
        do {
            let regex = try NSRegularExpression(pattern: #"<!(\w+)>"#, options: [])
            let matches = regex.matches(in: result as String, options: [], range: NSMakeRange(0, result.length))
            
            for match in matches.reversed() {
                let identifier = result.substring(with: match.range(at: 1))
                result = result.replacingCharacters(in: match.range, with: "@\(identifier)") as NSString
            }
        }
        catch {
        }
        
        return result as String
    }
    
    func detectMissingAgents(markup: String, chat: JVChat) -> [JVAgent] {
        guard chat.isGroup else {
            return []
        }
        
        do {
            let regex = try NSRegularExpression(pattern: #"\B(@(\d+))\b"#, options: [])
            let range = NSMakeRange(0, markup.utf16.count)
            let matches = regex.matches(in: markup, options: [], range: range)
            
            let result = NSString(string: markup)
            let missingAgents = matches.reversed().compactMap { match -> JVAgent? in
                let identifier = result.substring(with: match.range(at: 2)).jv_toInt()
                
                if let agent = agentsRepo.retrieve(id: identifier, lookup: .storedOnly) {
                    return chat.hasAttendee(agent: agent) ? nil : agent
                }
                else {
                    return nil
                }
            }
            
            return missingAgents
        }
        catch {
            return []
        }
    }
    
    private func findAllItems() -> [MentionsItem] {
        return []
            + broadcastIdentifiers.map(MentionsItem.broadcast)
            + agentsRepo.retrieveAll(listing: .exceptMe).map(MentionsItem.agent)
    }
    
    private func findItemsUsingPartialSearch(query: String) -> [MentionsItem] {
        let foundBroadcasts = broadcastIdentifiers.filter { identifier in
            guard !identifier.jv_search(.plain, query: query) else { return true }
            return false
        }
        
        let foundAgents = agentsRepo.retrieveAll(listing: .exceptMe).filter { agent in
            guard !agent.displayName(kind: .original).jv_search(.plain, query: query) else { return true }
            guard !agent.email.jv_search(.email, query: query) else { return true }
            return false
        }
        
        return []
            + foundBroadcasts.map(MentionsItem.broadcast)
            + foundAgents.map(MentionsItem.agent)
    }
    
    private func findItemUsingIdentifyingSearch(query: String) -> MentionsItem? {
        let foundBroadcasts = broadcastIdentifiers.filter { identifier in
            guard identifier != query else { return true }
            return false
        }
        
        if let broadcast = foundBroadcasts.first {
            return .broadcast(broadcast)
        }
        
        let mention = query.lowercased() + "@"
        let foundAgents = agentsRepo.retrieveAll(listing: .exceptMe).filter { agent in
            guard !agent.email.lowercased().hasPrefix(mention) else { return true }
            return false
        }
        
        if let agent = foundAgents.first {
            return .agent(agent)
        }
        
        return nil
    }
}
