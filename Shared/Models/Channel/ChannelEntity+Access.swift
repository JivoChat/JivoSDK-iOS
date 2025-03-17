//
//  ChannelEntity+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import UIKit

struct JVJointBundledValues {
    var channelTitle: String?
    var isStandalone: Bool
    var isContiguous: Bool
}

enum JVChannelJoint: String {
    case fb = "fb"
    case vk = "vk"
    case ok = "ok"
    case tg = "tg"
    case vb = "vb"
    case wa = "wa" // WhatsApp EDNA
    case wb = "wb" // WhatsApp Jivo == WhatsApp Business
    case tw = "tw" // WhatsApp Twilio
    case email = "email"
    case sdk = "sdk"
    case ya = "ya"
    case tel = "tel"
    case webhook = "bot" // WhatsApp if jointAlias == "sendpulse"
    case salute = "sb"
    case abc = "im"
    case ig = "ig"
    case drom = "drom"
    case ali = "ali"
    case avito = "av"
    case unknown
    
    var values: JVJointBundledValues {
        switch self {
        case .fb:
            return .init(
                channelTitle: loc["Client.Integration.FB"],
                isStandalone: true,
                isContiguous: true
            )
        case .vk:
            return .init(
                channelTitle: loc["Client.Integration.VK"],
                isStandalone: true,
                isContiguous: true
            )
        case .ok:
            return .init(
                channelTitle: loc["Client.Integration.OK"],
                isStandalone: true,
                isContiguous: true
            )
        case .tg:
            return .init(
                channelTitle: loc["Client.Integration.TG"],
                isStandalone: true,
                isContiguous: true
            )
        case .vb:
            return .init(
                channelTitle: loc["Client.Integration.VB"],
                isStandalone: true,
                isContiguous: true
            )
        case .wa, .tw, .wb:
            return .init(
                channelTitle: loc["Client.Integration.WA"],
                isStandalone: true,
                isContiguous: true
            )
        case .email:
            return .init(
                channelTitle: loc["Client.Integration.Email"],
                isStandalone: true,
                isContiguous: true
            )
        case .sdk:
            return .init(
                channelTitle: loc["Client.Integration.SDK"],
                isStandalone: true,
                isContiguous: true
            )
        case .ya:
            return .init(
                channelTitle: loc["Client.Integration.YA"],
                isStandalone: false,
                isContiguous: false
            )
        case .tel:
            return .init(
                channelTitle: loc["Client.Integration.Tel"],
                isStandalone: true,
                isContiguous: true
            )
        case .webhook:
            return .init(
                channelTitle: loc["Client.Integration.Bot"],
                isStandalone: true,
                isContiguous: true
            )
        case .salute:
            return .init(
                channelTitle: loc["Client.Integration.Salute"],
                isStandalone: false,
                isContiguous: true
            )
        case .abc:
            return .init(
                channelTitle: loc["Channel.Title.iMessage"],
                isStandalone: true,
                isContiguous: true
            )
        case .ig:
            return .init(
                channelTitle: loc["Client.Integration.Instagram"],
                isStandalone: true,
                isContiguous: true
            )
        case .drom:
            return .init(
                channelTitle: loc["Client.Integration.Drom"],
                isStandalone: false,
                isContiguous: false
            )
        case .ali:
            return .init(
                channelTitle: loc["Client.Integration.Aliexpress"],
                isStandalone: false,
                isContiguous: false
            )
        case .avito:
            return .init(
                channelTitle: loc["Client.Integration.Avito"],
                isStandalone: false,
                isContiguous: false
            )
        case .unknown:
            return .init(
                channelTitle: nil,
                isStandalone: false,
                isContiguous: true
            )
        }
    }
}

extension ChannelEntity {
    var ID: Int {
        return Int(m_id)
    }
    
    var jointID: String {
        return m_joint_id.jv_orEmpty
    }
    
    var publicID: String {
        return m_public_id.jv_orEmpty
    }
    
    var stateID: Int {
        return Int(m_state_id)
    }
    
    var siteURL: URL? {
        guard let m_site_url = m_site_url else { return nil}
        if #available(iOS 17.0, *) {
            return URL(string: m_site_url, encodingInvalidCharacters: false)
        } else {
            return URL(string: m_site_url)
        }
    }
    
    var name: String {
        return siteURL?.absoluteString ?? m_site_url ?? String()
    }
    
    var rawName: String {
        return m_site_url.jv_orEmpty
    }
    
    var guestsNumber: Int {
        return Int(m_guests_number)
    }
    
    var jointType: JVChannelJoint? {
        return m_joint_type.flatMap(JVChannelJoint.init)
    }
    
    var jointAlias: String {
        return m_joint_alias.jv_orEmpty
    }
    
    var jointURL: String {
        return m_joint_url ?? String()
    }
    
    var jointPhone: String {
        return m_joint_phone ?? String()
    }
    
    var jointVerifiedName: String {
        return m_joint_verified_name ?? String()
    }
    
    var isTestable: Bool {
        switch jointType {
        case nil:
            return true
        case .sdk?:
            return true
        default:
            return false
        }
    }
    
    var isSendpulse: Bool {
        return jointAlias == "sendpulse"
    }
    
    var isWhatsapp: Bool {
        if jointType == .wa { return true }
        if jointType == .wb { return true }
        if jointType == .tw { return true }
        if jointType == .webhook, isSendpulse { return true }
        return false
    }
    
    var isTelegram: Bool {
        if jointType == .tg { return true }
        return false
    }
    
    func hasAttachedAgent(ID agentID: Int) -> Bool {
        let query = ",\(agentID),"
        return m_agents_ids.jv_orEmpty.contains(query)
    }
    
    var icon: UIImage? {
        guard let joint = jointType
        else {
            return UIImage.jv_named("preview_chat")
        }
        
        switch joint {
        case .email:
            return UIImage.jv_named("preview_email")
        case .sdk:
            return UIImage.jv_named("preview_mobile")
        case .fb:
            return UIImage.jv_named("preview_fb")
        case .vk:
            return UIImage.jv_named("preview_vk")
        case .ok:
            return UIImage.jv_named("preview_ok")
        case .tg:
            return UIImage.jv_named("preview_tg")
        case .vb:
            return UIImage.jv_named("preview_vb")
        case .wa, .wb, .tw:
            return UIImage.jv_named("preview_wa")
        case .ya:
            return UIImage.jv_named("preview_ya")
        case .webhook:
            return UIImage.jv_named("preview_webhook")
        case .tel:
            return UIImage.jv_named("preview_tel")
        case .salute:
            return UIImage.jv_named("preview_chat")
        case .abc:
            return UIImage.jv_named("preview_abc")
        case .ig:
            return UIImage.jv_named("preview_ig")
        case .drom:
            return UIImage.jv_named("preview_drom")
        case .ali:
            return UIImage.jv_named("preview_ecomm")
        case .avito:
            return UIImage.jv_named("preview_avito")
        case .unknown:
            return UIImage.jv_named("preview_chat")
        }
    }
}
