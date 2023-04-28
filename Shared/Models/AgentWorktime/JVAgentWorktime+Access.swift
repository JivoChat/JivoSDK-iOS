//
//  JVAgentWorktime+Access.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation

extension JVAgentWorktime {
    public var agentID: Int {
        return Int(m_agent_id)
    }
    
    public var timezoneID: Int? {
        if m_timezone_id > 0 {
            return Int(m_timezone_id)
        }
        else {
            return nil
        }
    }
    
    public var timezone: JVTimezone? {
        return m_timezone
    }
    
    public var isEnabled: Bool {
        return m_is_enabled
    }
    
    public var todayConfig: JVAgentWorktimeDayConfig? {
        return unpackLocalConfig(day: .today)
    }
    
    public var nextMetaPair: JVAgentWorktimeDayMetaPair {
        return JVAgentWorktimeDayMetaPair(
            today: obtainNextDayMeta(includingToday: true),
            anotherDay: obtainNextDayMeta(includingToday: false)
        )
    }
    
    public var activeDays: Set<String> {
        let days = JVAgentWorktimeDay.allCases
        let configs = days.map(unpackLocalConfig)
        let activePairs = zip(days, configs).filter { day, config in config.enabled }
        return Set(activePairs.map { day, config in day.rawValue })
    }
    
    public func ifEnabled() -> JVAgentWorktime? {
        return m_is_enabled ? self : nil
    }
    
    public func obtainNextDayMeta(includingToday: Bool) -> JVAgentWorktimeDayMeta? {
        let originalSet = JVAgentWorktimeDay.allCases + JVAgentWorktimeDay.allCases
        guard let dayIndex = originalSet.firstIndex(of: .today) else { return nil }
        
        let offset = includingToday ? 0 : 1
        let valuableSet = originalSet.dropFirst(dayIndex + offset)
        
        for day in valuableSet {
            let config = unpackLocalConfig(day: day)
            if config.enabled {
                return JVAgentWorktimeDayMeta(day: day, config: config)
            }
        }
        
        return nil
    }
    
    public func unpackLocalConfig(day: JVAgentWorktimeDay) -> JVAgentWorktimeDayConfig {
        let source: Int64 = jv_convert(day) { day in
            switch day {
            case .monday:
                return m_monConfig
            case .tuesday:
                return m_tueConfig
            case .wednesday:
                return m_wedConfig
            case .thursday:
                return m_thuConfig
            case .friday:
                return m_friConfig
            case .saturday:
                return m_satConfig
            case .sunday:
                return m_sunConfig
            }
        }
        
        return JVAgentWorktimeDayConfig(
            enabled: ((source & 0xFF00000000) >> 32) > 0,
            startHour: Int((source & 0x00FF000000) >> 24),
            startMinute: Int((source & 0x0000FF0000) >> 16),
            endHour: Int((source & 0x000000FF00) >> 8),
            endMinute: Int((source & 0x00000000FF) >> 0)
        )
    }
}

public struct JVAgentWorktimePointPair {
    public var since: JVAgentWorktimePoint
    public var till: JVAgentWorktimePoint
    
    public init(since: JVAgentWorktimePoint, till: JVAgentWorktimePoint) {
        self.since = since
        self.till = till
    }
}

public struct JVAgentWorktimePoint: Comparable {
    public let hours: Int
    public let minutes: Int
    
    public init(hours: Int, minutes: Int) {
        self.hours = hours
        self.minutes = minutes
    }
    
    public func calculateSeconds() -> Int {
        return (hours * 60 + minutes) * 60
    }
    
    public static func <(lhs: JVAgentWorktimePoint, rhs: JVAgentWorktimePoint) -> Bool {
        if lhs.hours < rhs.hours {
            return true
        }
        else if lhs.hours == rhs.hours, lhs.minutes < rhs.minutes {
            return true
        }
        else {
            return false
        }
    }
}

public enum JVAgentWorktimeDay: String, CaseIterable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
    
    public static var today: JVAgentWorktimeDay {
        let component = JVActiveLocale().calendar.component(.weekday, from: Date())
        return JVAgentWorktimeDay.fromIndex(component - 1)
    }
    
    public static func fromIndex(_ index: Int) -> JVAgentWorktimeDay {
        switch index {
        case 0: return .sunday
        case 1: return .monday
        case 2: return .tuesday
        case 3: return .wednesday
        case 4: return .thursday
        case 5: return .friday
        case 6: return .saturday
        default: return .monday
        }
    }
    
    public var systemIndex: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}

public struct JVAgentWorktimeDayConfig: Equatable {
    public var enabled: Bool
    public var startHour: Int
    public var startMinute: Int
    public var endHour: Int
    public var endMinute: Int
    
    public init(
        enabled: Bool,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    ) {
        self.enabled = enabled
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
    }
    
    public var timeDescription: String {
        let sinceMins = staticTimeFormatter.jv_format(startMinute)
        let tillMins = staticTimeFormatter.jv_format(endMinute)
        return "\(startHour):\(sinceMins) - \(endHour):\(tillMins)"
    }
    
    public var date: Date {
        let baseDate = Date()
        return JVActiveLocale().calendar.date(
            bySettingHour: endHour,
            minute: endMinute,
            second: 0,
            of: baseDate) ?? baseDate
    }
}

public struct JVAgentWorktimeDayMeta: Equatable {
    public let day: JVAgentWorktimeDay
    public let config: JVAgentWorktimeDayConfig
    
    public init(day: JVAgentWorktimeDay, config: JVAgentWorktimeDayConfig) {
        self.day = day
        self.config = config
    }
}

public struct JVAgentWorktimeDayMetaPair: Equatable {
    public let today: JVAgentWorktimeDayMeta?
    public let anotherDay: JVAgentWorktimeDayMeta?
    
    public init(today: JVAgentWorktimeDayMeta?, anotherDay: JVAgentWorktimeDayMeta?) {
        self.today = today
        self.anotherDay = anotherDay
    }
}

fileprivate let staticTimeFormatter: NumberFormatter = {
    let result = NumberFormatter()
    result.minimumIntegerDigits = 2
    return result
}()

