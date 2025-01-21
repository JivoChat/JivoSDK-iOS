//
//  ReferralSourceEntity+Access.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 30.10.2024.
//

extension ReferralSourceEntity {
    enum Kind {
        case ad
        case campaign
        case other
    }
}

extension ReferralSourceEntity {
    var kind: Kind {
        if m_meta_json.jv_orEmpty.contains("ad_referral") {
            return .ad
        }
        else {
            return .other
        }
    }
    
    var imageUrl: URL? {
        if let link = m_image_link?.jv_valuable {
            return URL(string: link)
        }
        else {
            return nil
        }
    }
    
    var title: String? {
        return m_title?.jv_valuable
    }
    
    var text: String? {
        return m_text?.jv_valuable
    }
    
    var navigateUrl: URL? {
        if let link = m_navigate_link?.jv_valuable {
            return URL(string: link)
        }
        else {
            return nil
        }
    }
}
