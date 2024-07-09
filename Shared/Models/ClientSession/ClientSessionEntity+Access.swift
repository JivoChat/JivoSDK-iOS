//
//  ClientSessionEntity+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension ClientSessionEntity {
    var creationDate: Date? {
        if m_creation_ts > 0 {
            return Date(timeIntervalSince1970: m_creation_ts)
        }
        else if let firstPage = history.first {
            return firstPage.time?.jv_parseDateUsingFullFormat()
        }
        else {
            return nil
        }
    }
    
    var UTM: ClientSessionUtmEntity? {
        return m_utm
    }
    
    var lastIP: String? {
        return m_last_ip?.jv_valuable
    }
    
    var history: [PageEntity] {
        if let allObjects = m_history?.allObjects as? [PageEntity] {
            return allObjects
        }
        else {
            return Array()
        }
    }
    
    var geo: ClientSessionGeoEntity? {
        return m_geo
    }
    
    var chatStartPage: PageEntity? {
        return m_start_page ?? m_current_page ?? history.last
    }
    
    var currentPage: PageEntity? {
        return m_current_page
    }
}
