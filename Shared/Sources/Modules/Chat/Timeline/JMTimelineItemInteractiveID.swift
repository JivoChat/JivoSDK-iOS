//
//  JMTimelineItemInteractiveID.swift
//  JMTimeline
//
//  Created by Stan Potemkin on 01/10/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation


enum JMTimelineItemInteractiveID {
    case navigatedToPage(url: URL)
}

fileprivate let JMTimelineItemInteractiveNavigatedToPageKey = "navigated_to_page"

func JMTimelineItemInteractiveIDEncode(_ interactiveID: JMTimelineItemInteractiveID) -> String? {
    switch interactiveID {
    case .navigatedToPage(let url):
        let key = JMTimelineItemInteractiveNavigatedToPageKey
        let value = url.absoluteString.jv_escape() ?? ""
        return [key, value].joined(separator: " ")
    }
}

func JMTimelineItemInteractiveIDDecode(_ encoded: String?) -> JMTimelineItemInteractiveID? {
    guard let encoded = encoded else { return nil }
    
    if encoded.hasPrefix(JMTimelineItemInteractiveNavigatedToPageKey) {
        let args = encoded.components(separatedBy: CharacterSet.whitespaces)
        guard let link = args.last?.jv_unescape(), let url = URL(string: link) else { return nil }
        return .navigatedToPage(url: url)
    }

    return nil
}
