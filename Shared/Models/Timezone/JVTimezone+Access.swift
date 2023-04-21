//
//  JVTimezone+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension JVTimezone {
    public var ID: Int {
        return Int(m_id)
    }
    
    public var identifier: String {
        return m_identifier ?? String()
    }
    
    public var GMT: String {
        return m_display_gmt ?? String()
    }
    
    public func displayName(lang: JVLocaleLang) -> String {
        switch lang {
        case .ru:
            return m_display_name_ru ?? m_identifier ?? String()
        default:
            return m_display_name_en ?? m_identifier ?? String()
        }
    }
    
    public var sortingOffset: Int {
        return Int(m_sorting_offset)
    }
    
    public func sortingRegion(lang: JVLocaleLang) -> String {
        switch lang {
        case .ru:
            return m_sorting_region_ru ?? m_identifier ?? String()
        default:
            return m_sorting_region_en ?? m_identifier ?? String()
        }
    }
}
