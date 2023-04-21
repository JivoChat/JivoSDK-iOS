//
//  JVClientSessionUtm+Access.swift
//  App
//
//  Created by Stan Potemkin on 23.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension JVClientSessionUtm {
    public static func generateHumanReadable(
        source: String,
        medium: String,
        campaign: String,
        keyword: String,
        content: String
    ) -> String? {
        let parser = JVPureParserTool()
        
        if campaign.contains("organic") {
            // let socials = ["vk.com", "vkontakte.", "fb.com", "facebook."]
            // if socials.contains(where: source.contains)
            parser.assign(variable: "organicRef", value: source.jv_valuable)
            parser.activate(alias: "search", source.isEmpty)
            parser.assign(variable: "keyword", value: decodePercentage(keyword))
        }
        else if medium.contains("cpc") {
            parser.activate(alias: "cpc", true)
            parser.assign(variable: "keyword", value: decodePercentage(keyword))
            parser.assign(variable: "campaign", value: decodePercentage(campaign))
            parser.assign(variable: "content", value: decodePercentage(content))
            parser.assign(variable: "cpcRef", value: decodePercentage(source))
        }
        else if medium.contains("referral") || campaign.contains("referral") {
            let address = source + content
            if let components = URLComponents(string: address), components.scheme == nil {
                parser.assign(variable: "regularRef", value: "https://\(address)")
            }
            else {
                parser.assign(variable: "regularRef", value: address)
            }
        }
        else if source.contains("direct") || campaign.contains("direct") {
            parser.activate(alias: "direct", true)
        }
        else {
            parser.assign(variable: "source", value: decodePercentage(source))
            parser.assign(variable: "type", value: decodePercentage(medium))
            parser.assign(variable: "keyword", value: decodePercentage(keyword))
            parser.assign(variable: "campaign", value: decodePercentage(campaign))
            parser.assign(variable: "content", value: decodePercentage(content))
        }
        
        let formula = loc["Details.UTM.Formula"]
        let result = parser.execute(formula, collapseSpaces: true)
        
        let trimmingKit = CharacterSet(charactersIn: " ,")
        let trimmedResult = result.trimmingCharacters(in: trimmingKit)
        guard !trimmedResult.isEmpty else { return nil }
        
        return trimmedResult.jv_substringTo(index: 0).uppercased() + trimmedResult.jv_substringFrom(index: 1).lowercased()
    }
    
    private static func decodePercentage(_ input: String) -> String? {
        guard var output = input.jv_valuable else { return nil }
        
        while (true) {
            if let decoded = output.removingPercentEncoding {
                guard decoded != output else { break }
                output = decoded
            }
            else {
                break
            }
        }
        
        return output
    }
    
    public var humanReadable: String? {
        guard
            let source = m_source?.jv_valuable,
            let campaign = m_campaign?.jv_valuable
            else { return nil }
        
        let medium = m_medium ?? String()
        let keyword = m_keyword ?? String()
        let content = m_content ?? String()
        
        return JVClientSessionUtm.generateHumanReadable(
            source: source,
            medium: medium,
            campaign: campaign,
            keyword: keyword,
            content: content
        )
    }
}
