//
//  ClientCustomFieldEntity+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension ClientCustomFieldEntity {
    var title: String? {
        return m_title?.jv_valuable
    }
    
    var key: String? {
        return m_key?.jv_valuable
    }
    
    var content: String {
        return m_content.jv_orEmpty
    }
    
    var URL: URL? {
        if let link = m_link?.jv_valuable {
            if URLComponents(string: link)?.scheme == nil {
                return Foundation.URL(string: "https://" + link)
            }
            else {
                return Foundation.URL(string: link)
            }
        }
        else if let content = content.jv_valuable, content.contains("://") {
            return Foundation.URL(string: content)
        }
        else {
            return nil
        }
    }
}
