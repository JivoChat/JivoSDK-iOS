//
//  MentioningServiceDecl.swift
//  App
//
//  Created by Stan Potemkin on 09.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

/// interface for this subsystem
protocol IMentioningService: AnyObject {
    /// For given Caret position within the Text provided, detect the possible query for searching
    func extractPossibleQuery(text: String?, caret: Int?) -> MentionsDetection<String>
    /// For given Caret position within the Text provided, get a list of agents/channels relevant for the query
    func detectMentionWhileTyping(text: String?, caret: Int?) -> MentionsDetection<[MentionsItem]>
    /// Preprocess the textual content of sending message to convert mentions like @alex into markup like <@12345>
    func convertPlainToMarkup(text: String) -> String
    /// Preprocess the textual content of sending message to convert mentions like <@12345> into markup like @alex
    func convertMarkupToPlain(text: String) -> String
    /// With the markup provided, detect the unknown/missing agents accordingly to list of members within specific chat
    func detectMissingAgents(markup: String, chat: JVChat) -> [JVAgent]
}
