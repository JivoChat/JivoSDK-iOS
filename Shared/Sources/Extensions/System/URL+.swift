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

public enum JVUrlCommand {
    case addContact(phone: String, name: String)
}

public extension URL {
    static func jv_generateAvatarURL(ID: UInt64) -> (image: UIImage?, color: UIColor?) {
        let names = [
            "airplane", "apple", "ball", "bug" /*bee*/,
            "bug", "cat", "cloud", "coffee",
            "compass", "cookie", "crocodile", "diamond",
            "dolphin", "duck", "fish", "flag",
            "ghost", "glass", "leaf", "light",
            "night", "octopus", "owl", "panda",
            "penguin", "pinetree", "pizza", "robot",
            "rocket", "saxophone", "star1",
            "sun", "sword", "tie", "trafficlight",
            "umbrella", "whale", "wolf"
        ]

        let colors = [
            "9D28B2", "673AB7", "3D4EB8", "00A8F7",
            "00CBD4", "009788", "49B04C", "8BC34A"
        ]

        let name = "zoo_" + names[Int(ID % UInt64(names.count - 1))]
        let color = colors[Int(ID % UInt64(colors.count - 1))]
        
        return (
            image: UIImage(named: name),
            color: UIColor(jv_hex: color)
        )
    }

    static func jv_privacy() -> URL? {
        return URL(string: UIApplication.openSettingsURLString)
    }
    
    static func jv_recoverPassword(domain: String, email: String, lang: String) -> URL? {
        return URL(string: "https://admin.\(domain)")?.build(
            "/auth/forgot-password",
            query: ["email": email, "lang": lang]
        )
    }
    
    static func jv_mailto(mail: String) -> URL? {
        return URL(string: "mailto:\(mail)")
    }
    
    static func jv_call(phone: String, countryCode: String?) -> URL? {
        let badSymbols = NSCharacterSet(charactersIn: "+0123456789").inverted
        let goodPhone = phone.jv_stringByRemovingSymbols(of: badSymbols)
        let goodCountryCode = countryCode ?? String()
        return URL(string: "tel:\(goodPhone)?\(goodCountryCode)")
    }
    
    static func jv_location(coordinate: CLLocationCoordinate2D) -> URL? {
        return URL(string: "http://maps.apple.com/maps")?.build(
            query: ["saddr": "\(coordinate.latitude),\(coordinate.longitude)"]
        )
    }
    
    static func jv_review(applicationID: Int) -> URL? {
        return URL(string: "itms-apps://itunes.apple.com/app/id\(applicationID)")?.build(
            query: ["action": "write-review"]
        )
    }
    
    static func jv_notificationAck(host: String, siteID: Int, agentID: Int, pushID: String) -> URL? {
        return URL(string: "https://\(host)/push/delivery/\(siteID)/\(agentID)/\(pushID)")?.build(
            query: ["platform": "ios"]
        )
    }
    
    static func jv_customerAckEndpoint() -> URL? {
        return URL(string: "https://track.customer.io/push/events")
    }
    
    static func jv_commandAddContact(phone: String, name: String) -> URL? {
        return URL(string: "internal://add-contact")?
            .build(query: ["phone": phone, "name": name])
    }

    static func jv_widgetSumulator(domain: String, siteLink: String, channelID: String, codeHost: String?, lang: String) -> URL? {
        return URL(string: "https://app.\(domain)/simulate_widget.html")?.build(
            query: [
                "site": siteLink,
                "widget_id": channelID,
                "locale": lang,
                "code_host": codeHost ?? "code"
            ]
        )
    }

    func jv_parseCommand() -> JVUrlCommand? {
        if let host = host {
            var params = [String: String]()
            if let components = URLComponents(url: self, resolvingAgainstBaseURL: false) {
                components.queryItems?.forEach { params[$0.name] = $0.value }
            }
            
            switch host {
            case "add-contact":
                guard let phone = params["phone"] else { return nil }
                guard let name = params["name"] else { return nil }
                return JVUrlCommand.addContact(phone: phone, name: name)

            default:
                return nil
            }
        }
        else {
            return nil
        }
    }

    var jv_fileSize: Int64? {
        guard isFileURL else { return nil }
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path) else { return nil }
        guard let size = attributes[.size] as? NSNumber else { return nil }
        return size.int64Value
    }
    
    var jv_debugQuerylessFull: String {
        guard var c = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return String() }
        c.queryItems = nil
        return c.url?.absoluteString ?? absoluteString
    }
    
    var jv_debugQuerylessCompact: String {
        return path
    }
    
    var jv_debugFull: String {
        guard let c = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return String() }
        let queries: [String] = (c.queryItems ?? []).map({ item in "\t&\(item.name)=\(item.value ?? String())\n" })
        return "\(jv_debugQuerylessFull)?\n\(queries.joined())"
    }
    
    var jv_debugCompact: String {
        return jv_debugQuerylessCompact
    }
    
    /*
    var jv_utmHumanReadable: String? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems,
            let source = queryItems.jv_value(forName: "utm_source"),
            let campaign = queryItems.jv_value(forName: "utm_campaign")
            else { return nil }
        
        let medium = queryItems.jv_value(forName: "utm_medium") ?? String()
        let keyword = queryItems.jv_value(forName: "utm_term") ?? String()
        let content = queryItems.jv_value(forName: "utm_content") ?? String()
        
        return _JVClientSessionUTM.generateHumanReadable(
            source: source,
            medium: medium,
            campaign: campaign,
            keyword: keyword,
            content: content
        )
    }
    */
    
    func jv_unarchive<T: Codable>(type: T.Type) -> T? {
        let filePath = path
        return try? handle({ NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? T })
    }
    
    func jv_normalized() -> URL {
        guard URLComponents(url: self, resolvingAgainstBaseURL: false)?.scheme == nil else { return self }
        return URL(string: "http://" + absoluteString) ?? self
    }
    
    func jv_excludedFromBackup() -> URL {
        var duplicate = self
        
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? duplicate.setResourceValues(values)
        
        return duplicate
    }
}

public extension URLRequest {
    var jv_debugFull: String {
        guard let url = url else { return String() }
        guard let c = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return String() }

        let queries: [String] = (c.queryItems ?? []).map({ item in "\t&\(item.name)=\(item.value ?? String())\n" })
        let body = httpBody.flatMap({ String(data: $0, encoding: .utf8) }) ?? String()

        return "\(url.jv_debugQuerylessFull)?\n\(queries.joined())\n\(body)"
    }

    var jv_debugCompact: String {
        guard let url = url else { return String() }
        return url.jv_debugCompact
    }
}

public extension URLResponse {
    var jv_debugFull: String {
        guard let url = url else { return String() }

        if let http = self as? HTTPURLResponse {
            return "\(url.jv_debugQuerylessFull) status[\(http.statusCode)]\n"
        }
        else {
            return url.jv_debugQuerylessFull
        }
    }

    var jv_debugCompact: String {
        guard let url = url else { return String() }
        
        if let http = self as? HTTPURLResponse {
            return "\(url.jv_debugQuerylessCompact) status[\(http.statusCode)]"
        }
        else {
            return url.jv_debugQuerylessCompact
        }
    }
}

public extension Array where Element == URLQueryItem {
    func jv_value(forName name: String) -> String? {
        guard let item = first(where: { $0.name == name }) else { return nil }
        return item.value
    }
}
