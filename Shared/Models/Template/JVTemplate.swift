//
//  JVTemplate.swift
//  App
//
//  Created by Julia Popova on 04.04.2024.
//

import Foundation
import JMCodingKit

@objc(JVTemplate)
class JVTemplate: JVDatabaseModel {
    override func apply(context: JVIDatabaseContext, change: JVDatabaseModelChange) {
        super.apply(context: context, change: change)
        performApply(context: context, environment: context.environment, change: change)
    }
}

extension JVTemplate {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        
        if let c = change as? JVTemplateGeneralChange {
            m_id = Int64(c.templateId)
            m_wa_account_id = Int64(c.waAccountId)
            m_status = c.status
            m_language = c.language
            m_components = c.components
            m_category = c.category
            m_name = c.name
        }
    }
    
    var components: [JsonElement] {
        if let m_components = m_components {
            
            guard let jsonToDecode = m_components.data(using: .utf8) else { return [] }
            guard let jsonToParse = JsonCoder().decode(binary: jsonToDecode, encoding: .utf8)?.arrayValue else { return [] }
            return jsonToParse
        } else {
            return []
        }
    }
}

final class JVTemplateGeneralChange: JVDatabaseModelChange, Codable {
    var templateId: Int
    var waAccountId: Int
    var name: String
    var language: String
    var category: String
    var status: String
    var components: String
    var templateLocalId: String
    
    override var stringKey: JVDatabaseModelCustomId<String>? {
        return JVDatabaseModelCustomId(key: "m_local_id", value: templateLocalId)
    }
    
    override var primaryValue: Int {
        templateId
    }
    
    required init(json: JsonElement) {
        category = json["category"].stringValue
        waAccountId = json["wb_account_id"].intValue
        status = json["status"].stringValue
        name = json["name"].stringValue
        templateId = Int(truncating: json["template_id"].numberValue)
        language = json["language"].stringValue
        components = json["components"].array?.description ?? ""
        
        templateLocalId = json["name"].stringValue + "_" + language + String(waAccountId)
        
        super.init(json: json)
    }
}
