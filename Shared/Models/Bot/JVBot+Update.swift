//
//  JVBot+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVBot {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = m_id
        }
        
        if let c = change as? JVBotGeneralChange {
            m_id = Int64(c.id)
            m_avatar_link = c.avatarLink?.jv_valuable
            m_display_name = c.displayName ?? String()
            m_title = c.title ?? String()
        }
    }
}

final class JVBotGeneralChange: JVDatabaseModelChange, Codable {
    public let id: Int
    public let avatarLink: String?
    public let displayName: String?
    public let title: String?
    
    override var primaryValue: Int {
        return id
    }
    
    public required init(json: JsonElement) {
        id = json["bot_id"].intValue
        avatarLink = json["avatar_url"].string
        displayName = json["display_name"].string
        title = json["title"].string
        
        super.init(json: json)
    }
    
    init(placeholderID: Int) {
        id = placeholderID
        avatarLink = nil
        displayName = nil
        title = nil

        super.init()
    }
    
    init(id: Int,
                avatarLink: String?,
                displayName: String?,
                title: String?) {
        self.id = id
        self.avatarLink = avatarLink
        self.displayName = displayName
        self.title = title
        super.init()
    }
    
    func cachable() -> JVBotGeneralChange {
        return JVBotGeneralChange(
            id: id,
            avatarLink: avatarLink,
            displayName: displayName,
            title: title)
    }
}
