//
//  JVClientCustomField+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVClientCustomField {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let c = change as? JVClientCustomDataGeneralChange {
            m_title = c.title
            m_key = c.key
            m_content = c.content
            m_link = c.link
        }
    }
}

final class JVClientCustomDataGeneralChange: JVDatabaseModelChange {
    public let title: String?
    public let key: String?
    public let content: String
    public let link: String?
    
    required init(json: JsonElement) {
        title = json["title"].string?.jv_valuable
        key = json["key"].string?.jv_valuable
        content = json["content"].stringValue
        link = json["link"].string?.jv_valuable
        super.init(json: json)
    }
}
