//
//  ChatTimelineReferralSourceInfo.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 31.10.2024.
//

import UIKit
import JMTimelineKit

struct ChatTimelineReferralSourceInfo: JMTimelineInfo {
    let imageInfo: ImageInfo?
    let title: String?
    let text: String?
    let navigateUrl: URL?
}

extension ChatTimelineReferralSourceInfo {
    struct ImageInfo {
        let url: URL
        let width: Int
        let height: Int
    }
}

extension ChatTimelineReferralSourceInfo {
    var hasAnyCaptions: Bool {
        if !title.jv_orEmpty.isEmpty {
            return true
        }
        
        if !text.jv_orEmpty.isEmpty {
            return true
        }
        
        if let _ = navigateUrl {
            return true
        }
        
        return false
    }
}
