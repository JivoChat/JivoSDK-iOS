//
//  ChannelEntity+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension ChannelEntity {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = m_id
        }
        
        if let c = change as? JVChannelBlankChange {
            m_id = c.ID.jv_toInt64(.standard)
        }
        else if let c = change as? JVChannelGeneralChange {
            m_id = c.ID.jv_toInt64(.standard)
            m_public_id = c.publicID
            m_state_id = c.stateID.jv_toInt16(.standard)
            m_site_url = c.siteURL
            m_guests_number = c.guestsNumber.jv_toInt16(.standard)
            m_joint_type = c.jointType ?? ""
            m_joint_alias = c.jointAlias.jv_orEmpty
            m_joint_url = c.jointURL ?? ""
            m_joint_phone = c.phone
            m_joint_verified_name = c.verifiedName
            m_joint_id = c.jointID ?? ""
            m_agents_ids = "," + c.agentIDs.jv_stringify().joined(separator: ",") + ","
        }
    }
}

final class JVChannelBlankChange: JVDatabaseModelChange {
    public let ID: Int
    
    override var primaryValue: Int {
        return ID
    }
    
    init(ID: Int) {
        self.ID = ID
        super.init()
    }
    
    required init(json: JsonElement) {
        fatalError()
    }
}

final class JVChannelGeneralChange: JVDatabaseModelChange, Codable {
    public let ID: Int
    public let publicID: String
    public let stateID: Int
    public let siteURL: String
    public let phone: String
    public let verifiedName: String
    public let guestsNumber: Int
    public let jointType: String?
    public let jointAlias: String?
    public let jointURL: String?
    public let jointID: String?
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
        jointAlias = info["joint_alias"].string
        jointURL = info["prepared_joint_options"]["url"].stringValue
        jointID = info["prepared_joint_options"]["id"].stringValue
        phone = info["prepared_joint_options"]["phone"].stringValue
        verifiedName = info["prepared_joint_options"]["verified_name"].stringValue
        agentIDs = json["agents"].intArray ?? []
        super.init(json: json)
    }
}
