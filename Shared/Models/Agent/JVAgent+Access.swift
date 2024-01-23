//
//  JVAgent+Access.swift
//  App
//
//  Created by Stan Potemkin on 16.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMRepicKit

enum JVAgentState: Int {
    case none
    case active
    case away
}

enum JVAgentCallingDestination: Int {
    case disabled = 0
    case sip = 1
    case phone = 2
    case app = 3

    var isExternal: Bool {
        switch self {
        case .disabled: return false
        case .sip: return true
        case .phone: return true
        case .app: return false
        }
    }
}

enum JVAgentCallingOptions: Int {
    case availableForCalls
    case availableForMobileCalls
    case onCall
    case supportsAway
    case supportsOffline
}

enum JVAgentOrderingGroup: Int {
    case offline
    case awayZZ
    case onlineZZ
    case away
    case online
}

extension JVAgent {
    var stateColor: UIColor? {
        switch state {
        case .none:
            return nil
        case .active:
            return JVDesign.colors.resolve(usage: .onlineTint)
        case .away:
            return JVDesign.colors.resolve(usage: .awayTint)
        }
    }
}

extension JVAgent: JVDisplayable {
    var senderType: JVSenderType {
        return .agent
    }

    var ID: Int {
        return Int(m_id)
    }
    
    var publicID: String {
        return m_public_id.jv_orEmpty
    }
    
    var email: String {
        return m_email.jv_orEmpty
    }
    
    var emailVerified: Bool {
        return m_email_verified
    }
    
    var nickname: String {
        return email.split(separator: "@").first.flatMap(String.init) ?? String()
    }
    
    var phone: String? {
        return m_phone?.jv_valuable
    }
    
    var isMe: Bool {
        return (m_session != nil)
    }
    
    var notMe: Bool {
        return !isMe
    }
    
    var state: JVAgentState {
        get {
            return JVAgentState(rawValue: Int(m_state_id)) ?? .active
        }
        set {
            m_state_id = Int16(newValue.rawValue)
        }
    }
    
    var status: JVAgentStatus? {
        return m_status
    }
    
    var statusComment: String {
        return m_status_comment.jv_orEmpty
    }
    
    var isWorktimeEnabled: Bool {
        return m_session?.isWorking ?? m_is_working
    }
    
    var channel: JVChannel? {
        return nil
    }
    
    var statusImage: UIImage? {
        switch state {
        case .active where isWorktimeEnabled:
            return UIImage(named: "status_def_online")
        case .active:
            return UIImage(named: "status_def_online_sleep")
        case .away where isWorktimeEnabled:
            return UIImage(named: "status_def_away")
        case .away:
            return UIImage(named: "status_def_away_sleep")
        case .none where isWorktimeEnabled:
            return UIImage(named: "status_def_offline")
        case .none:
            return UIImage(named: "status_def_offline_sleep")
        }
    }
    
    func repicItem(transparent: Bool, scale: CGFloat?) -> JMRepicItem? {
        let url = m_avatar_link.flatMap(URL.init)
        let icon = UIImage(named: "avatar_agent", in: .jv_shared, compatibleWith: nil)
        let image = JMRepicItemSource.avatar(URL: url, image: icon, color: nil, transparent: transparent)
        return JMRepicItem(backgroundColor: nil, source: image, scale: scale ?? 1.0, clipping: .dual)
    }
    
    func displayName(kind: JVDisplayNameKind) -> String {
        switch kind {
        case .original where (-1...0).contains(m_id):
            return .jv_empty
        case .original:
            return m_display_name.jv_orEmpty
        case .short:
            let originalName = displayName(kind: .original)
            let clearName = originalName.trimmingCharacters(in: .whitespaces)
            let slices = (clearName as NSString).components(separatedBy: .whitespaces)
            return (slices.count > 1 ? "\(slices[0]) \(slices[1].prefix(1))." : clearName)
        case .decorative(let decor):
            return [
                displayName(kind: .original),
                (decor.contains(.role) && m_is_operator ? "✨" : nil),
                (decor.contains(.status) ? m_status?.emoji : nil)
            ].compactMap{$0}.joined()
        case .relative where isMe:
            return loc["Message.Sender.You"]
        case .relative:
            return displayName(kind: .original)
        }
    }
    
    var title: String {
        return m_title.jv_orEmpty
    }
    
    var channels: String {
        return m_channels.jv_orEmpty
    }
    
    var isOwner: Bool {
        return m_is_owner
    }
    
    var isAdmin: Bool {
        return m_is_admin
    }

    var isOperator: Bool {
        return m_is_operator
    }

    var callingDestination: JVAgentCallingDestination {
        return JVAgentCallingDestination(rawValue: Int(m_calling_destination)) ?? .disabled
    }

    var draft: String? {
        return m_draft?.jv_valuable
    }
    
    func availableForChatInvite(operatorsOnly: Bool) -> Bool {
        if operatorsOnly, !isOperator {
            return false
        }
        
        switch state {
        case .none:
            return false
        case .active:
            return true
        case .away:
            return true
        }
    }

    func availableForChatTransfer(operatorsOnly: Bool) -> Bool {
        if operatorsOnly, !(isOperator) {
            return false
        }
        
        switch state {
        case .none:
            return false
        case .active:
            return true
        case .away:
            return true
        }
    }

    var availableForCallTransfer: Bool {
        if isMe {
            return false
        }
        
        if callingDestination == .disabled {
            return false
        }

        switch state {
        case .none where callingDestination.isExternal:
            return Int(m_calling_options).jv_hasBit(JVAgentCallingOptions.supportsOffline.rawValue)
        case .none:
            return false
        case .active:
            return true
        case .away:
            return Int(m_calling_options).jv_hasBit(JVAgentCallingOptions.supportsAway.rawValue)
        }
    }

    var session: JVAgentSession? {
        return m_session
    }
    
    var lastMessage: JVMessage? {
        return m_last_message
    }
    
    var chat: JVChat? {
        return m_chat
    }
    
    var integration: JVChannelJoint? {
        return nil
    }
    
    var hashedID: String {
        return "agent:\(ID)"
    }

    var isAvailable: Bool {
        switch state {
        case .none:
            return false
        case .active:
            return true
        case .away:
            return true
        }
    }

    var onCall: Bool {
        return Int(m_calling_options).jv_hasBit(1 << JVAgentCallingOptions.onCall.rawValue)
    }
    
    var worktime: JVAgentWorktime? {
        return m_worktime
    }
    
    var hasSession: Bool {
        return m_has_session
    }
    
    var lastMessageDate: Date? {
        return m_last_message_date
    }
    
    var orderingGroup: Int {
        return Int(m_ordering_group)
    }
    
    var orderingName: String {
        return m_ordering_name.jv_orEmpty
    }
    
    var isExisting: Bool {
        return !(m_email.jv_orEmpty.isEmpty)
    }
}
