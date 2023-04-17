//
//  JVMessageImage+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension JVMessageImage {
    var fileName: String {
        return m_file_name.jv_orEmpty
    }
    
    var URL: URL {
        return (NSURL(string: m_url.jv_orEmpty) ?? NSURL()) as URL
    }
    
    var uploadDate: Date {
        return Date(timeIntervalSince1970: m_upload_ts)
    }
}
