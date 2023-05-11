//
//  JVMessageImage+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVMessageImage {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let c = change as? JVMessageImageGeneralChange {
            m_file_name = c.fileName
            m_url = c.URL
            m_upload_ts = Double(c.uploadTS)
        }
    }
}

final class JVMessageImageGeneralChange: JVDatabaseModelChange {
    public let fileName: String
    public let URL: String
    public let uploadTS: Int
    
    required init(json: JsonElement) {
        fileName = json["filename"].stringValue
        URL = json["url"].stringValue
        uploadTS = json["uploaded_ts"].intValue
        super.init(json: json)
    }
}
