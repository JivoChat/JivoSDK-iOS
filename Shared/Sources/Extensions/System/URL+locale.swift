//
//  URLExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 31/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import SafeURL
import CoreLocation
import SwiftyNSException

public extension URL {
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
    
    static func jv_feedback(domain: String, session: String, lang: JVLocaleLang, siteID: Int, agentID: Int, name: String, app: String, design: String) -> URL? {
        /*
         ru: jivosite.ru
         en: jivochat.com
         pt: jivochat.com.br
         ptEu: jivochat.pt
         es: jivochat.es
         de: jivochat.de
         id: jivochat.co.id
         tr: jivochat.com.tr
         ng: jivochat.ng
         ke: jivochat.co.ke
         za: jivochat.co.za
         esAr: jivochat.com.ar
         cl: jivochat.cl
         bo: jivochat.com.bo
         mx: jivochat.mx
         ve: jivochat.com.ve
         co: jivochat.com.co
         pe: jivochat.com.pe
         in: jivochat.co.in
         uk: jivochat.co.uk
         nl: jivochat.nl
         gh: jivochat.com.gh
         */
        
        let endpoint: String // = "https://ip.yandex.ru/"/.
        #if ENV_DEBUG
        endpoint = "https://\(lang.jv_developmentPrefix).site.dev.\(domain)/feedback"
        #else
        endpoint = "https://\(lang.jv_productionHost)/feedback"
        #endif
        
        return URL(string: endpoint)?.build(
            query: ["session": session, "siteid": siteID, "agentid": agentID, "name": name, "description": app, "design": design]
        )
    }
}

extension JVLocaleLang {
    public var jv_developmentPrefix: String {
        switch self {
        case .en: return "en"
        case .ru: return "ru"
        case .es: return "es"
        case .pt: return "pt"
        case .tr: return "tr"
        case .hy: return "hy"
        }
    }
    
    public var jv_productionHost: String {
        switch self {
        case .ru: return "jivosite.\(jv_productionDomain)"
        default: return "jivochat.\(jv_productionDomain)"
        }
    }
    
    public var jv_productionDomain: String {
        switch self {
        case .en: return "com"
        case .ru: return "ru"
        case .es: return "es"
        case .pt: return "com.br"
        case .tr: return "com.tr"
        case .hy: return "com"
        }
    }
    
    public var jv_feedbackEmail: String {
        switch self {
        case .tr: return "bilgi@\(jv_productionHost)"
        default: return "info@\(jv_productionHost)"
        }
    }
}
