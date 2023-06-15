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
    var ID: String {
        return m_id.jv_orEmpty
    }
    
    var lang: String {
        return m_lang.jv_orEmpty
    }
    
    var tags: [String] {
        return m_tags.jv_orEmpty
            .components(separatedBy: QuickPhraseStorageSeparator)
            .filter { !$0.isEmpty }
    }
    
    var text: String {
        return m_text.jv_orEmpty
    }
    
    func export() -> JVQuickPhraseGeneralChange {
        return JVQuickPhraseGeneralChange(
            ID: ID,
            lang: lang,
            tag: tags.first ?? String(" "),
            text: text
        )
    }
}
