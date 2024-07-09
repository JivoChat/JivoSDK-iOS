//
//  ClientSessionEntity+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension ClientSessionEntity {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let c = change as? JVClientSessionGeneralChange {
            m_creation_ts = c.creationTS ?? m_creation_ts
            m_last_ip = c.lastIP
            
            e_history.setSet(Set(context.insert(of: PageEntity.self, with: c.history)))

            if let value = c.UTM {
                m_utm = context.insert(of: ClientSessionUtmEntity.self, with: value)
            }
            
            if let value = c.geo {
                m_geo = context.insert(of: ClientSessionGeoEntity.self, with: value)
            }
            
            if let value = c.chatStartPage {
                m_start_page = context.insert(of: PageEntity.self, with: value)
            }
            
            if let value = c.currentPage {
                m_current_page = context.insert(of: PageEntity.self, with: value)
            }
        }
    }
    
    private var e_history: NSMutableSet {
        return mutableSetValue(forKeyPath: #keyPath(ClientSessionEntity.m_history))
    }
}

final class JVClientSessionGeneralChange: JVDatabaseModelChange {
    public let creationTS: TimeInterval?
    public let UTM: JVClientSessionUTMGeneralChange?
    public let lastIP: String
    public let history: [JVPageGeneralChange]?
    public let geo: JVClientSessionGeoGeneralChange?
    public let chatStartPage: JVPageGeneralChange?
    public let currentPage: JVPageGeneralChange?
    
    required init(json: JsonElement) {
        if let value = json.has(key: "created_ts") {
            creationTS = value.doubleValue
        }
        else if let _ = json.has(key: "created_datetime") {
            creationTS = nil
            
//            if let date = value.string?.parseDateUsingFullFormat() {
//                creationTS = Int(date.timeIntervalSince1970)
//            }
//            else {
//                creationTS = nil
//            }
        }
        else {
            creationTS = nil
        }
        
        UTM = (json.has(key: "utm") ?? json).parse()
        lastIP = json["ip"].stringValue
        history = json["prechat_navigates"].parseList()
        geo = json.has(key: "geoip")?.parse() ?? json.has(key: "social")?.parse() ?? nil
        chatStartPage = json["chat_start_page"].parse()
        currentPage = json["prechat_navigates"].array?.first?.parse()
        super.init(json: json)
    }
}
