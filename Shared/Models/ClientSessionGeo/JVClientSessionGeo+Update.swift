//
//  JVClientSessionGeo+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVClientSessionGeo {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let c = change as? JVClientSessionGeoGeneralChange {
            m_country = c.country
            m_region = c.region
            m_city = c.city
            m_organization = c.organization
            m_country_code = c.countryCode
        }
    }
}

public final class JVClientSessionGeoGeneralChange: JVDatabaseModelChange {
    public let country: String?
    public let region: String?
    public let city: String?
    public let organization: String?
    public let countryCode: String?
    
    required public init(json: JsonElement) {
        if let demographics = json.has(key: "demographics") {
            let location = demographics["locationDeduced"]
            country = location["country"]["name"].valuable
            region = location["state"]["name"].valuable
            city = location["city"]["name"].valuable
            organization = nil
            countryCode = location["country"]["code"].valuable
        }
        else {
            country = json["country"].valuable
            region = json["region"].valuable
            city = json["city"].valuable
            organization = json["organization"].valuable
            countryCode = json["country_code"].valuable
        }
        
        super.init(json: json)
    }
}
