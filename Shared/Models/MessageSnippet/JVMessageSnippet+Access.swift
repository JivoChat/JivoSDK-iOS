//
//  JVMessageSnippet+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension JVMessageSnippet {
    var URL: URL? {
        if let link = m_url, let url = NSURL(string: link) {
            return url as URL
        }
        else {
            return nil
        }
    }
    
    var title: String {
        return m_title.jv_orEmpty
    }
    
    var iconURL: URL? {
        if let link = m_icon_url, let url = NSURL(string: link) {
            return url as URL
        }
        else {
            return nil
        }
    }
    
    var HTML: String {
        return m_html.jv_orEmpty
    }
}
