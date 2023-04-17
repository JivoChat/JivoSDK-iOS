//
//  JVClientSessionUtm+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVClientSessionUtm {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let c = change as? JVClientSessionUTMGeneralChange {
            m_source = c.source
            m_keyword = c.keyword
            m_campaign = c.campaign
            m_medium = c.medium
            m_content = c.content
        }
    }
}

public final class JVClientSessionUTMGeneralChange: JVDatabaseModelChange {
    public let source: String?
    public let keyword: String?
    public let campaign: String?
    public let medium: String?
    public let content: String?
    
    public override var isValid: Bool {
        let components = [source, keyword, campaign, medium, content]
        if components.contains(where: { $0.jv_hasValue }) {
            return true
        }
        else {
            return false
        }
    }
    
    required public init(json: JsonElement) {
        source = json["source"].valuable?.jv_unescape()
        keyword = json["keyword"].valuable?.jv_unescape()
        campaign = json["campaign"].valuable?.jv_unescape()
        medium = json["medium"].valuable?.jv_unescape()
        content = json["content"].valuable?.jv_unescape()
        super.init(json: json)
    }
}
