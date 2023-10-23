//
//  JVTimezone+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVTimezone {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = Int64(m_id)
        }
        
        if let c = change as? JVTimezoneGeneralChange {
            let defaultTimezone = TimeZone(identifier: c.code) ?? .current
            let gmtOffset = TimeZone(identifier: c.code)?.secondsFromGMT() ?? 0
            let localeEn = Locale(identifier: "en_US")
            let localeRu = Locale(identifier: "ru_RU")
            let metaEn = extractMeta(c.displayNameEn)
            let metaRu = extractMeta(c.displayNameRu)
            
            m_id = c.ID.jv_toInt16(.standard)
            m_identifier = c.code
            m_display_name_en = c.displayNameEn
            m_display_name_ru = c.displayNameRu
            
            m_display_gmt = (metaEn ?? metaRu)?.gmt
            m_sorting_offset = ((metaEn ?? metaRu)?.offset ?? gmtOffset).jv_toInt32(.standard)
            m_sorting_region_en = metaEn?.region ?? defaultTimezone.localizedName(for: .generic, locale: localeEn)
            m_sorting_region_ru = metaRu?.region ?? defaultTimezone.localizedName(for: .generic, locale: localeRu)
        }
    }
    
    private func extractMeta(_ name: String?) -> (gmt: String, offset: Int, region: String)? {
        guard let name = name else { return nil }
        
        do {
            let regex = try NSRegularExpression(pattern: #"^\((GMT([+-])(\d{2}):(\d{2}))\)\s*(.*)\s*$"#, options: [])
            let range = NSRange(location: 0, length: name.count)
            guard let match = regex.firstMatch(in: name, options: [], range: range) else { return nil }
            
            let gmtRange = match.range(at: 1)
            let signRange = match.range(at: 2)
            let hourRange = match.range(at: 3)
            let minuteRange = match.range(at: 4)
            let regionRange = match.range(at: 5)

            let isPositive = ((name as NSString).substring(with: signRange) == "+")
            let hour = (name as NSString).substring(with: hourRange).jv_toInt()
            let minute = (name as NSString).substring(with: minuteRange).jv_toInt()
            
            return (
                gmt: (name as NSString).substring(with: gmtRange),
                offset: (hour * 3600 + minute * 60) * (isPositive ? 1 : -1),
                region: (name as NSString).substring(with: regionRange)
            )
        }
        catch {
            return nil
        }
    }
}

final class JVTimezoneGeneralChange: JVDatabaseModelChange, Codable {
    private enum Keys: CodingKey {
        case ID
        case code
        case displayNameEn
        case displayNameRu
    }
    
    public let ID: Int
    public let code: String
    public let displayNameEn: String?
    public let displayNameRu: String?
    
    override var primaryValue: Int {
        return ID
    }
    
    override var isValid: Bool {
        guard ID > 0 else { return false }
        guard !code.isEmpty else { return false }
        return true
    }
    
    required init(json: JsonElement) {
        ID = json["timezone_id"].intValue
        code = json["code"].stringValue
        displayNameEn = json["display_name_en"].string
        displayNameRu = json["display_name_ru"].string
        super.init(json: json)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        ID = try container.decode(Int.self, forKey: .ID)
        code = try container.decode(String.self, forKey: .code)
        displayNameEn = try container.decodeIfPresent(String.self, forKey: .displayNameEn)
        displayNameRu = try container.decodeIfPresent(String.self, forKey: .displayNameRu)

        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(ID, forKey: .ID)
        try container.encode(code, forKey: .code)
        try container.encodeIfPresent(displayNameEn, forKey: .displayNameEn)
        try container.encodeIfPresent(displayNameRu, forKey: .displayNameRu)
    }
}
