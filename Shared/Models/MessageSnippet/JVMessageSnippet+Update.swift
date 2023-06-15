//
//  JVMessageSnippet+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVMessageSnippet {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let c = change as? JVMessageSnippetGeneralChange {
            m_url = c.URL
            m_title = c.title
            m_icon_url = c.iconURL
        }
    }
}

final class JVMessageSnippetGeneralChange: JVDatabaseModelChange {
    public let URL: String?
    public let title: String
    public let iconURL: String?
    public let HTML: String
    
    required init(json: JsonElement) {
        URL = json["url"].valuable
        title = json["title"].stringValue
        iconURL = json["icon"].valuable
        HTML = json["html"].stringValue
        super.init(json: json)
    }
}
