//
//  QuickPhraseEntity+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension QuickPhraseEntity {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_str = m_id
        }
        
        if let c = change as? JVQuickPhraseGeneralChange {
            m_id = c.ID
            m_lang = c.lang
            m_tags = ([String()] + c.tags + [String()]).joined(separator: QuickPhraseStorageSeparator)
            m_text = c.text
        }
    }
}

final class JVQuickPhraseGeneralChange: JVDatabaseModelChange {
    public let ID: String
    public let lang: String
    public let tags: [String]
    public let text: String
    
    override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_id", value: ID)
    }
    
    init(lang language: String, json: JsonElement) {
        ID = json["id"].string?.jv_valuable ?? UUID().uuidString.lowercased()
        lang = language
        tags = jv_with(json["tags"]) { $0.string.flatMap({[$0]}) ?? $0.stringArray }
        text = json["text"].stringValue
        super.init(json: json)
    }
    
    init(ID: String,
         lang: String,
         tag: String,
         text: String) {
        self.ID = ID
        self.lang = lang
        self.tags = [tag]
        self.text = text
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
    
    override var isValid: Bool {
        guard !ID.isEmpty else { return false }
        guard !lang.isEmpty else { return false }
        guard !tags.isEmpty else { return false }
        guard !text.isEmpty else { return false }
        return true
    }
    
    func encode() -> JsonElement {
        return JsonElement(
            [
                "id": ID,
                "tags": tags,
                "text": text
            ] as [String: Any]
        )
    }
    
    public static func ==(lhs: JVQuickPhraseGeneralChange, rhs: JVQuickPhraseGeneralChange) -> Bool {
        guard lhs.ID == rhs.ID else { return false }
        return true
    }
}
