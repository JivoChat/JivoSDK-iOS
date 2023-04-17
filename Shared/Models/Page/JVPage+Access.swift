//
//  JVPage+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

public extension JVPage {
    var URL: URL? {
        return Foundation.URL(string: m_url.jv_orEmpty)
    }
    
    var title: String {
        return m_title.jv_orEmpty
    }
    
    var time: Date? {
        return m_time?.jv_parseDateUsingFullFormat()
    }
}
