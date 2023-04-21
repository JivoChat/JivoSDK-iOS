//
//  JVQuickPhrase+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

let QuickPhraseStorageSeparator = ","

extension JVQuickPhrase {
    public var ID: String {
        return m_id.jv_orEmpty
    }
    
    public var lang: String {
        return m_lang.jv_orEmpty
    }
    
    public var tags: [String] {
        return m_tags.jv_orEmpty
            .components(separatedBy: QuickPhraseStorageSeparator)
            .filter { !$0.isEmpty }
    }
    
    public var text: String {
        return m_text.jv_orEmpty
    }
    
    public func export() -> JVQuickPhraseGeneralChange {
        return JVQuickPhraseGeneralChange(
            ID: ID,
            lang: lang,
            tag: tags.first ?? String(" "),
            text: text
        )
    }
}
