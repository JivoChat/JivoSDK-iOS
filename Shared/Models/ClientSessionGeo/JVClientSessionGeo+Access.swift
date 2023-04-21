//
//  JVClientSessionGeo+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension JVClientSessionGeo {
    public var country: String? {
        return m_country?.jv_valuable
    }
    
    public var region: String? {
        return m_region?.jv_valuable
    }
    
    public var city: String? {
        return m_city?.jv_valuable
    }
    
    public var organization: String? {
        return m_organization?.jv_valuable
    }
    
    public var countryCode: String? {
        return m_country_code?.jv_valuable?.lowercased()
    }
}
