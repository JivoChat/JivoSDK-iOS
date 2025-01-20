//
//  ReferralSourceEntity+Update.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 30.10.2024.
//

import Foundation
import JMCodingKit

extension ReferralSourceEntity {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_str = m_id
        }
        
        if let c = change as? ReferralSourceGeneralChange {
            m_id = c.id
            m_meta_json = c.metaJson
            m_image_link = c.imageLink
            m_title = c.title
            m_text = c.text
            m_navigate_link = c.navigateLink
        }
    }
}

final class ReferralSourceGeneralChange: JVDatabaseModelChange {
    let id: String
    let metaJson: String
    let imageLink: String
    let title: String
    let text: String
    let navigateLink: String

    override var isValid: Bool {
        guard !metaJson.isEmpty else { return false }
        return true
    }
    
    required init(json: JsonElement) {
        id = UUID().uuidString
        metaJson = json["address"].stringValue
        imageLink = json["file"].stringValue
        title = json["title"].stringValue
        text = json["text"].stringValue
        navigateLink = json["url"].stringValue
        super.init(json: json)
    }
}
