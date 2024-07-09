//
//  BotEntity+Access.swift
//  App
//
//  Created by Stan Potemkin on 16.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMRepicKit

extension BotEntity: JVDisplayable {
    var channel: ChannelEntity? {
        return nil
    }
    
    var integration: JVChannelJoint? {
        nil
    }
    
    var isMe: Bool {
        false
    }
    
    var isAvailable: Bool {
        return true
    }
    
    var senderType: JVSenderType {
        return .bot
    }
    
    var id: Int {
        return Int(m_id)
    }
    
    var title: String {
        return m_title.jv_orEmpty
    }
    
    var hashedID: String {
        return "bot:\(id)"
    }
    
    func repicItem(transparent: Bool, scale: CGFloat?) -> JMRepicItem? {
        let url = m_avatar_link.flatMap(URL.init)
        let icon = UIImage(named: "avatar_bot", in: .jv_shared, compatibleWith: nil)
        let image = JMRepicItemSource.avatar(URL: url, image: icon, color: nil, transparent: transparent)
        return JMRepicItem(backgroundColor: nil, source: image, scale: scale ?? 1.0, clipping: .dual)
    }
    
    func displayName(kind: JVDisplayNameKind) -> String {
        switch kind {
        case .original:
            return m_display_name.jv_orEmpty
        case .short:
            let originalName = displayName(kind: .original)
            let clearName = originalName.trimmingCharacters(in: .whitespaces)
            let slices = (clearName as NSString).components(separatedBy: .whitespaces)
            return (slices.count > 1 ? "\(slices[0]) \(slices[1].prefix(1))." : clearName)
        case .decorative:
            return displayName(kind: .original)
        case .relative:
            return displayName(kind: .original)
        }
    }
}
