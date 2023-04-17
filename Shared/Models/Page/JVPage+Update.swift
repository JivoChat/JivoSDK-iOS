//
//  JVPage+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVPage {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let c = change as? JVPageGeneralChange {
            m_url = c.URL
            m_title = c.title
            m_time = c.time
        }
    }
}

public final class JVPageGeneralChange: JVDatabaseModelChange {
    public let URL: String
    public let title: String
    public let time: String?
    
    public override var isValid: Bool {
        if URL.isEmpty {
            return false
        }
        else if let _ = NSURL(string: URL) {
            return true
        }
        else {
            return false
        }
    }
    
    required public init(json: JsonElement) {
        URL = json["url"].stringValue
        title = json["title"].stringValue
        time = json["time"].string
        super.init(json: json)
    }
}
