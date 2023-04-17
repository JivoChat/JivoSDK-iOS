//
//  JVMessageMedia+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVMessageMedia {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let c = change as? JVMessageMediaGeneralChange {
            m_type = c.type
            m_mime = c.mime ?? ""
            m_thumb_link = c.thumbLink ?? ""
            m_full_link = c.fullLink
            m_emoji = c.emoji ?? ""
            m_size = c.size.jv_toInt32
            m_width = c.width.jv_toInt32
            m_height = c.height.jv_toInt32
            m_duration = c.duration.jv_toInt32
            m_latitude = c.latitude ?? 0
            m_longitude = c.longitude ?? 0
            m_phone = c.phone ?? ""
            m_title = c.title
            m_link = c.link
            m_text = c.text

            let name = (c.title.jv_valuable ?? c.name).jv_trimmedZeros()
            if let performer = c.performer?.jv_trimmedZeros() {
                m_name = "\(performer) - \(name)"
            }
            else {
                m_name = name
            }
        }
    }
}

public final class JVMessageMediaGeneralChange: JVDatabaseModelChange {
    public let type: String
    public let mime: String?
    public let thumbLink: String?
    public let fullLink: String
    public let emoji: String?
    public let name: String
    public let title: String
    public let performer: String?
    public let size: Int
    public let width: Int
    public let height: Int
    public let duration: Int
    public let latitude: Double?
    public let longitude: Double?
    public let phone: String?
    public let link: String?
    public let text: String?

    public override var isValid: Bool {
        guard type != "error" else { return false }
        return true
    }
    
    public init(type: String, mime: String, name: String, link: String, size: Int, width: Int, height: Int) {
        self.type = type
        self.mime = mime
        self.thumbLink = nil
        self.fullLink = link
        self.emoji = nil
        self.name = name
        self.title = self.name
        self.performer = nil
        self.size = size
        self.width = width
        self.height = height
        self.duration = 0
        self.latitude = nil
        self.longitude = nil
        self.phone = nil
        self.link = nil
        self.text = nil
        super.init()
    }
    
    required public init(json: JsonElement) {
        type = json["type"].stringValue
        mime = nil
        thumbLink = json["thumb"].stringValue
        fullLink = json["file"].stringValue
        emoji = json["emoji"].string
        name = json["file_name"].string?.jv_valuable ?? json["name"].stringValue
        title = json["title"].stringValue
        performer = json["performer"].string
        size = json["file_size"].intValue
        width = json["width"].intValue
        height = json["height"].intValue
        duration = json["duration"].intValue
        latitude = json["latitude"].double ?? json["latitude"].string?.jv_toDouble()
        longitude = json["longitude"].double ?? json["longitude"].string?.jv_toDouble()
        phone = json["phone"].string
        link = json["url"].string
        text = json["text"].string
        super.init(json: json)
    }
}
