//
//  JVChannel+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import UIKit

public enum JVChannelJoint: String {
    case fb = "fb"
    case vk = "vk"
    case ok = "ok"
    case tg = "tg"
    case vb = "vb"
    case wa = "wa"
    case email = "email"
    case sdk = "sdk"
    case ya = "ya"
    case tel = "tel"
    case webhook = "bot"
    case salute = "sb"
    case abc = "im"
    case ig = "ig"
    case drom = "drom"
    case ali = "ali"
    case unknown
    
    public var localizedChannelTitle: String? {
        switch self {
        case .fb: return loc["Client.Integration.FB"]
        case .vk: return loc["Client.Integration.VK"]
        case .ok: return loc["Client.Integration.OK"]
        case .tg: return loc["Client.Integration.TG"]
        case .vb: return loc["Client.Integration.VB"]
        case .wa: return loc["Client.Integration.WA"]
        case .email: return loc["Client.Integration.Email"]
        case .sdk: return loc["Client.Integration.SDK"]
        case .ya: return loc["Client.Integration.YA"]
        case .tel: return loc["Client.Integration.Tel"]
        case .webhook: return loc["Client.Integration.Bot"]
        case .salute: return loc["Client.Integration.Salute"]
        case .abc: return loc["Channel.Title.iMessage"]
        case .ig: return loc["Client.Integration.Instagram"]
        case .drom: return loc["Client.Integration.Drom"]
        case .ali: return loc["Client.Integration.Aliexpress"]
        case .unknown: return nil
        }
    }
    
    public var localizedContactTitle: String? {
        switch self {
        case .fb: return loc["Client.Integration.FB"]
        case .vk: return loc["Client.Integration.VK"]
        case .ok: return loc["Client.Integration.OK"]
        case .tg: return loc["Client.Integration.TG"]
        case .vb: return loc["Client.Integration.VB"]
        case .wa: return loc["Client.Integration.WA"]
        case .email: return loc["Client.Integration.Email"]
        case .sdk: return loc["Client.Integration.SDK"]
        case .ya: return loc["Client.Integration.YA"]
        case .webhook: return loc["Client.Integration.Bot"]
        case .tel: return loc["Channel.Title.Phone"]
        case .salute: return loc["Client.Integration.Salute"]
        case .abc: return loc["Channel.Title.iMessage"]
        case .ig: return loc["Client.Integration.Instagram"]
        case .drom: return loc["Channel.Title.Drom"]
        case .ali: return loc["Channel.Title.Aliexpress"]
        case .unknown: return nil
        }
    }
    
    public var isStandalone: Bool {
        switch self {
        case .fb: return true
        case .vk: return true
        case .ok: return true
        case .tg: return true
        case .vb: return true
        case .wa: return true
        case .email: return true
        case .sdk: return true
        case .ya: return false
        case .webhook: return true
        case .tel: return true
        case .salute: return false
        case .abc: return true
        case .ig: return true
        case .drom: return false
        case .ali: return false
        case .unknown: return false
        }
    }
    
    public var isContiguous: Bool {
        switch self {
        case .fb: return true
        case .vk: return true
        case .ok: return true
        case .tg: return true
        case .vb: return true
        case .wa: return true
        case .email: return true
        case .sdk: return true
        case .ya: return false
        case .webhook: return true
        case .tel: return true
        case .salute: return true
        case .abc: return true
        case .ig: return true
        case .drom: return false
        case .ali: return false
        case .unknown: return true
        }
    }
}

extension JVChannel {
    public var ID: Int {
        return Int(m_id)
    }
    
    public var publicID: String {
        return m_public_id.jv_orEmpty
    }
    
    public var stateID: Int {
        return Int(m_state_id)
    }
    
    public var siteURL: URL? {
        return m_site_url.flatMap(URL.init)
    }
    
    public var name: String {
        return siteURL?.absoluteString ?? m_site_url ?? String()
    }
    
    public var guestsNumber: Int {
        return Int(m_guests_number)
    }
    
    public var jointType: JVChannelJoint? {
        return m_joint_type.flatMap(JVChannelJoint.init)
    }
    
    public var isTestable: Bool {
        switch jointType {
        case nil:
            return true
        case .sdk?:
            return true
        default:
            return false
        }
    }
    
    public func hasAttachedAgent(ID agentID: Int) -> Bool {
        let query = ",\(agentID),"
        return m_agents_ids.jv_orEmpty.contains(query)
    }
    
    public var icon: UIImage? {
        guard let joint = jointType
        else {
            return UIImage(named: "preview_chat")
        }
        
        switch joint {
        case .email:
            return UIImage(named: "preview_email")
        case .sdk:
            return UIImage(named: "preview_mobile")
        case .fb:
            return UIImage(named: "preview_fb")
        case .vk:
            return UIImage(named: "preview_vk")
        case .ok:
            return UIImage(named: "preview_ok")
        case .tg:
            return UIImage(named: "preview_tg")
        case .vb:
            return UIImage(named: "preview_vb")
        case .wa:
            return UIImage(named: "preview_wa")
        case .ya:
            return UIImage(named: "preview_ya")
        case .webhook:
            return UIImage(named: "preview_webhook")
        case .tel:
            return UIImage(named: "preview_tel")
        case .salute:
            return UIImage(named: "preview_chat")
        case .abc:
            return UIImage(named: "preview_abc")
        case .ig:
            return UIImage(named: "preview_ig")
        case .drom:
            return UIImage(named: "preview_drom")
        case .ali:
            return UIImage(named: "preview_ecomm")
        case .unknown:
            return UIImage(named: "preview_chat")
        }
    }
}
