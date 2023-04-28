//
//  JVDepartment+Access.swift
//  App
//
//  Created by Stan Potemkin on 16.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
import JMRepicKit

extension JVDepartment: JVDisplayable {
    public var ID: Int {
        return Int(m_id)
    }
    
    public var name: String {
        return m_name.jv_orEmpty
    }
    
    var icon: String {
        return m_icon.jv_orEmpty.jv_convertToEmojis()
    }
    
    var brief: String {
        return m_brief.jv_orEmpty
    }
    
    func corresponds(to channel: JVChannel) -> Bool {
        return m_channels_ids.jv_orEmpty
            .contains(",\(channel.ID),")
    }
    
    public var agentsIds: [Int] {
        return m_agents_ids.jv_orEmpty
            .split(separator: ",")
            .filter { !$0.isEmpty }
            .map { String($0).jv_toInt() }
    }
    
    public var channel: JVChannel? {
        return nil
    }
    
    public func displayName(kind: JVDisplayNameKind) -> String {
        return name
    }
    
    public var integration: JVChannelJoint? {
        return nil
    }
    
    public var hashedID: String {
        return "department:\(ID)"
    }
    
    public var isMe: Bool {
        return false
    }
    
    public var isAvailable: Bool {
        return true
    }
    
    public var senderType: JVSenderType {
        return .department
    }
    
    public func repicItem(transparent: Bool, scale: CGFloat?) -> JMRepicItem? {
        return JMRepicItem(
            backgroundColor: JVDesign.colors.resolve(usage: .contentBackground),
            source: .caption(icon, JVDesign.fonts.emoji(scale: nil)),
            scale: 1.0,
            clipping: .external
        )
    }
}
