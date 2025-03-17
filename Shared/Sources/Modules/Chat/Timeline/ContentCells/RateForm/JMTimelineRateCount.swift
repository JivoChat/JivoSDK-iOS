//
//  JMTimelineRateCount.swift
//  JivoSDK
//
//  Created by Julia Popova on 26.09.2023.
//

import Foundation

enum JMTimelineRateCount: Int, Codable {
    case two = 2
    case three = 3
    case five = 5
    
    init(_ rawValue: String) {
        switch rawValue {
        case "two": self = .two
        case "three": self = .three
        case "five": self = .five
        default: self = .five
        }
    }
}

extension JMTimelineRateCount {
    private var minRate: Int {
        return 1
    }
    
    private var maxRate: Int {
        switch self {
        case .two: return 2
        case .three: return 3
        case .five: return 5
        }
    }
    
    func stringRepresentance(for rate: Int) -> String {
        if rate == self.minRate { return "bad" }
        if rate == self.maxRate { return "good" }
        
        let averageRate = (self.minRate + self.minRate) / 2
        if rate == averageRate {
            return "normal"
        } else if rate > averageRate {
            return "goodnormal"
        } else {
            return "badnormal"
        }
    }
}
