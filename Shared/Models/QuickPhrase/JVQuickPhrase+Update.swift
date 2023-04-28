//
//  JVQuickPhrase+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
import JMCodingKit

extension JVQuickPhrase {
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

public final class JVQuickPhraseGeneralChange: JVDatabaseModelChange {
    public let ID: String
    public let lang: String
    public let tags: [String]
    public let text: String
    
    public override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_id", value: ID)
    }
    
    public init(lang language: String, json: JsonElement) {
        ID = json["id"].string?.jv_valuable ?? UUID().uuidString.lowercased()
        lang = language
        tags = jv_with(json["tags"]) { $0.string.flatMap({[$0]}) ?? $0.stringArray }
        text = json["text"].stringValue
        super.init(json: json)
    }
    
    public init(ID: String,
         lang: String,
         tag: String,
         text: String) {
        self.ID = ID
        self.lang = lang
        self.tags = [tag]
        self.text = text
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
    
    public override var isValid: Bool {
        guard !ID.isEmpty else { return false }
        guard !lang.isEmpty else { return false }
        guard !tags.isEmpty else { return false }
        guard !text.isEmpty else { return false }
        return true
    }
    
    public func encode() -> JsonElement {
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
