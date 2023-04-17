//
//  JVDepartment+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVDepartment {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = m_id
        }
        
        if let c = change as? JVDepartmentGeneralChange {
            m_id = Int64(c.id)
            m_name = c.name
            m_icon = c.icon
            m_brief = c.brief
            
            m_channels_ids = (
                c.channelsIds.isEmpty
                ? String()
                : "," + c.channelsIds.map(String.init).joined(separator: ",") + ","
            )
            
            m_agents_ids = (
                c.agentsIds.isEmpty
                ? String()
                : "," + c.agentsIds.map(String.init).joined(separator: ",") + ","
            )
        }
    }
}

public final class JVDepartmentGeneralChange: JVDatabaseModelChange, Codable {
    public let id: Int
    public let name: String
    public let icon: String
    public let brief: String
    public let channelsIds: [Int]
    public let agentsIds: [Int]

    public override var primaryValue: Int {
        return id
    }
    
    public required init(json: JsonElement) {
        id = json["group_id"].intValue
        name = json["name"].stringValue
        icon = json["icon"].stringValue
        brief = json["description"].stringValue
        channelsIds = json["widget_ids"].intArray ?? Array()
        agentsIds = json["agent_ids"].intArray ?? Array()

        super.init(json: json)
    }
}
