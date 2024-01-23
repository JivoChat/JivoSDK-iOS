//
//  ChatTimelineRateScale.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 28.12.2023.
//

import Foundation

struct ChatTimelineRateScale: Codable {
    let mark: JMTimelineRateIcon
    let aliases: [String]
}

extension ChatTimelineRateScale {
    var range: Range<Int> {
        return (0 ..< aliases.count)
    }
    
    var shouldHighlightLeadingMarks: Bool {
        return (mark == .star)
    }
    
    func shouldTakeAsPositive(choice: Int) -> Bool {
        return (choice > (range.count - 1) / 2)
    }
}
