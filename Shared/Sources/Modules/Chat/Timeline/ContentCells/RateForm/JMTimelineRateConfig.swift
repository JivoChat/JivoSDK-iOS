//
//  JMTimelineRateConfig.swift
//  JivoSDK
//
//  Created by Julia Popova on 26.09.2023.
//

import JMCodingKit

struct JMTimelineRateConfig: Codable {
    let scale: ChatTimelineRateScale
    let rateCondition: JMTimelineRateCondition
    let rateConditionValue: Int
    let goodRateTitle: String?
    let badRateTitle: String?
    let customRateTitle: String?
    
    init(json: JsonElement) {
        let aliasesMapping: [(alias: String, ranges: [RateRange])] = [
            ("bad", [.two, .three, .five]),
            ("badnormal", [.five]),
            ("normal", [.three, .five]),
            ("goodnormal", [.five]),
            ("good", [.two, .three, .five]),
        ]
        
        let mark = JMTimelineRateIcon(rawValue: json["icon"].stringValue) ?? .star
        let range = RateRange(rawValue: json["type"].stringValue) ?? .five
        let aliases = aliasesMapping.filter({ $0.ranges.contains(range) }).map(\.alias)
        scale = ChatTimelineRateScale(mark: mark, aliases: aliases)
        
        self.rateCondition = .init(rawValue: json["condition_name"].stringValue) ?? .messagesCount
        self.rateConditionValue = json["condition_value"].intValue
        self.goodRateTitle = json["good_rate_title"].string
        self.badRateTitle = json["bad_rate_title"].string
        self.customRateTitle = json["custom_title"].string
    }
}

fileprivate enum RateRange: String {
    case two
    case three
    case five
}
