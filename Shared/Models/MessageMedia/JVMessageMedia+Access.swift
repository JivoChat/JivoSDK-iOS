//
//  JVMessageMedia+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import CoreLocation

public enum JVMessageMediaType {
    case photo
    case sticker
    case document
    case audio
    case voice
    case video
    case comment
    case location
    case contact
    case conference
    case story
    case unknown
}

public enum JVMessageMediaSizingMode {
    case original
    case cropped
}

extension JVMessageMedia {
    public var type: JVMessageMediaType {
        switch m_type {
        case "photo":
            return .photo
        case "sticker":
            return .sticker
        case "document":
            return .document
        case "audio":
            return .audio
        case "voice":
            return .voice
        case "video":
            return .video
        case "comment":
            return .comment
        case "location":
            return .location
        case "contact":
            return .contact
        case "conference":
            return .conference
        case "story":
            return .story
        default:
            return .unknown
        }
    }
    
    public var mime: String {
        return m_mime.jv_orEmpty
    }
    
    public var thumbURL: URL? {
        if m_thumb_link.jv_orEmpty.isEmpty {
            return nil
        }
        else if let url = NSURL(string: m_thumb_link.jv_orEmpty) {
            return url as URL
        }
        else {
            return nil
        }
    }
    
    public var fullURL: URL? {
        if m_full_link.jv_orEmpty.isEmpty {
            return nil
        }
        else if let url = NSURL(string: m_full_link.jv_orEmpty) {
            return url as URL
        }
        else {
            return nil
        }
    }
    
    public var emoji: String? {
        return m_emoji?.jv_valuable
    }
    
    public var name: String? {
        return m_name?.jv_valuable
    }
    
    public var dataSize: Int {
        return Int(m_size)
    }
    
    public var duration: TimeInterval {
        return TimeInterval(m_duration)
    }
    
    public var coordinate: CLLocationCoordinate2D? {
        if m_latitude == 0, m_longitude == 0 {
            return nil
        }
        else {
            return CLLocationCoordinate2D(latitude: m_latitude, longitude: m_longitude)
        }
    }
    
    public var conference: JVMessageBodyConference? {
        guard type == .conference else {
            return nil
        }
        
        if let link = m_link, !(link.isEmpty) {
            let url = URL(string: link)
            return JVMessageBodyConference(url: url, title: m_title.jv_orEmpty)
        }
        else {
            return JVMessageBodyConference(url: nil, title: m_title.jv_orEmpty)
        }
    }
    
    public var story: JVMessageBodyStory? {
        guard type == .story else {
            return nil
        }
        
        return JVMessageBodyStory(
            text: m_text.jv_orEmpty,
            fileName: m_name.jv_orEmpty,
            thumb: thumbURL,
            file: fullURL,
            title: m_title.jv_orEmpty
        )
    }
    
    public var phone: String? {
        return m_phone?.jv_valuable
    }
    
    public var text: String? {
        return m_text?.jv_valuable
    }
    
    public var originalSize: CGSize {
        let width = CGFloat(m_width)
        let height = CGFloat(m_height)
        return CGSize(width: width, height: height)
    }
    
    public func pixelSize(minimum: CGFloat = 0, maximum: CGFloat = 0) -> (CGSize, JVMessageMediaSizingMode) {
        let width = CGFloat(m_width) / UIScreen.main.scale
        let height = CGFloat(m_height) / UIScreen.main.scale
        let minimalSide = min(width, height)
        
        if minimalSide == 0 {
            return (.zero, .original)
        }
        else if minimum > 0, minimalSide < minimum {
            let size = CGSize(width: minimum, height: minimum)
            return (size, .cropped)
        }
        else if maximum > 0, minimalSide > maximum {
            let size = CGSize(width: maximum, height: maximum)
            return (size, .cropped)
        }
        else {
            let size = CGSize(width: minimalSide, height: minimalSide)
            return (size, .cropped)
        }
    }
}