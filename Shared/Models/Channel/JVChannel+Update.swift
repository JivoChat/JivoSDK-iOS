//
//  JVChannel+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVChannel {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = m_id
        }
        
        if let c = change as? JVChannelGeneralChange {
            m_id = c.ID.jv_toInt64
            m_public_id = c.publicID
            m_state_id = c.stateID.jv_toInt16
            m_site_url = c.siteURL
            m_guests_number = c.guestsNumber.jv_toInt16
            m_joint_type = c.jointType ?? ""
            m_agents_ids = "," + c.agentIDs.jv_stringify().joined(separator: ",") + ","
        }
    }
}

final class JVChannelGeneralChange: JVDatabaseModelChange {
    public let ID: Int
    public let publicID: String
    public let stateID: Int
    public let siteURL: String
    public let guestsNumber: Int
    public let jointType: String?
    public let agentIDs: [Int]
    
    override var primaryValue: Int {
        return ID
    }
    
    required init(json: JsonElement) {
        let info = json["widget_info"]
        ID = info["widget_id"].intValue
        publicID = info["public_id"].stringValue
        stateID = info["widget_status_id"].intValue
        siteURL = info["site_url"].stringValue
        guestsNumber = info["visitors_insight"].intValue
        jointType = info["joint_type"].string
        agentIDs = json["agents"].intArray ?? []
        super.init(json: json)
    }
}
