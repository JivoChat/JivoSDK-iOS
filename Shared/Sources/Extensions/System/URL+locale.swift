//
//  URLExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 31/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyNSException

extension URL {
    static func jv_welcome() -> URL? {
        let link = loc["Menu.VisitWeb.URL"]
        return URL(string: link)
    }
    
    static func jv_license() -> URL? {
        let link = loc["License.PricingURL"]
        return URL(string: link)
    }
    
    static func jv_privacyPolicy() -> URL? {
        let link = loc["Signup.PrivacyPolicy.Link"]
        return URL(string: link)
    }
}

extension JVLocaleLang {
    var jv_developmentPrefix: String {
        switch self {
        case .en: return "en"
        case .ru: return "ru"
        case .es: return "es"
        case .pt: return "pt"
        case .tr: return "tr"
        case .hy: return "hy"
        }
    }
    
    var jv_productionHost: String {
        switch self {
        case .ru: return "jivosite.\(jv_productionDomain)"
        default: return "jivochat.\(jv_productionDomain)"
        }
    }
    
    var jv_productionDomain: String {
        switch self {
        case .en: return "com"
        case .ru: return "ru"
        case .es: return "es"
        case .pt: return "com.br"
        case .tr: return "com.tr"
        case .hy: return "com"
        }
    }
    
    var jv_feedbackEmail: String {
        switch self {
        case .tr: return "bilgi@\(jv_productionHost)"
        default: return "info@\(jv_productionHost)"
        }
    }
}
