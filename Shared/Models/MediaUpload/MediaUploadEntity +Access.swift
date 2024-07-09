//
//  MediaUploadEntity+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension MediaUploadEntity {
    var ID: String {
        return m_id.jv_orEmpty
    }
    
    var fileURL: URL? {
        return URL(string: m_file_path.jv_orEmpty)
    }

    var purpose: JVMediaUploadingPurpose? {
        switch m_recipient_type {
        case "self":
            return .avatar
            
        default:
            guard let type = JVSenderType(rawValue: m_recipient_type.jv_orEmpty) else { return nil }
            let target = JVSenderData(type: type, ID: Int(m_recipient_id))
            return .transfer(target, chatID: Int(m_chat_id))
        }
    }
}
