//
//  JMTimelineMediaItem.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMTimelineKit

extension Notification.Name {
    static let JMMediaPlayerState = Notification.Name("JMMediaPlayerState")
}

protocol JMTimelineMediaInfo {
}

struct JMTimelineMediaVideoInfo: JMTimelineMediaInfo {
    let URL: URL
    let title: String?
    let duration: TimeInterval?
    let style: JMTimelineMediaStyle
    
    init(
        URL: URL,
        title: String?,
        duration: TimeInterval?,
        style: JMTimelineMediaStyle
    ) {
        self.URL = URL
        self.title = title
        self.duration = duration
        self.style = style
    }
}

struct JMTimelineMediaDocumentInfo: JMTimelineMediaInfo {
    let URL: URL
    let title: String?
    let dataSize: Int64?
    let style: JMTimelineMediaStyle
    let caption: String?
    let plainStyle: JMTimelineCompositePlainStyle?
    
    init(
        URL: URL,
        title: String?,
        dataSize: Int64?,
        style: JMTimelineMediaStyle,
        caption: String?,
        plainStyle: JMTimelineCompositePlainStyle?
    ) {
        self.URL = URL
        self.title = title
        self.dataSize = dataSize
        self.style = style
        self.caption = caption
        self.plainStyle = plainStyle
    }
}

struct JMTimelineMediaContactInfo: JMTimelineMediaInfo {
    let name: String
    let phone: String
    let style: JMTimelineMediaStyle
    
    init(name: String,
                phone: String,
                style: JMTimelineMediaStyle) {
        self.name = name
        self.phone = phone
        self.style = style
    }
}

typealias JMTimelineMediaStyle = JMTimelineCompositeMediaStyle

final class JMTimelineMediaItem: JMTimelinePayloadItem<JMTimelineMediaInfo> {
}
