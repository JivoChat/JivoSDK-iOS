//
//  JVAgentWorktime+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVAgentWorktime {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = m_agent_id
        }
        
        if let c = change as? JVAgentWorktimeBaseChange, m_agent_id == 0 {
            m_agent_id = c.agentID.jv_toInt64
        }
        
        if let c = change as? JVAgentWorktimeGeneralChange {
            if m_agent_id == 0 { m_agent_id = c.agentID.jv_toInt64 }
            
            m_timezone_id = c.timezoneID.jv_toInt16
            m_timezone = context.object(JVTimezone.self, primaryId: Int(m_timezone_id))
            
            if !m_is_dirty {
                m_is_enabled = c.enabled
                
                storeLocalConfig(
                    unpackRemoteConfig(enabled: c.monEnabled, start: c.monStart, end: c.monEnd),
                    forDay: .monday
                )
                
                storeLocalConfig(
                    unpackRemoteConfig(enabled: c.tueEnabled, start: c.tueStart, end: c.tueEnd),
                    forDay: .tuesday
                )
                
                storeLocalConfig(
                    unpackRemoteConfig(enabled: c.wedEnabled, start: c.wedStart, end: c.wedEnd),
                    forDay: .wednesday
                )
                
                storeLocalConfig(
                    unpackRemoteConfig(enabled: c.thuEnabled, start: c.thuStart, end: c.thuEnd),
                    forDay: .thursday
                )
                
                storeLocalConfig(
                    unpackRemoteConfig(enabled: c.friEnabled, start: c.friStart, end: c.friEnd),
                    forDay: .friday
                )
                
                storeLocalConfig(
                    unpackRemoteConfig(enabled: c.satEnabled, start: c.satStart, end: c.satEnd),
                    forDay: .saturday
                )
                
                storeLocalConfig(
                    unpackRemoteConfig(enabled: c.sunEnabled, start: c.sunStart, end: c.sunEnd),
                    forDay: .sunday
                )
            }
            
            m_last_update = Date()
        }
        else if let c = change as? JVAgentWorktimeTimezoneChange {
            m_timezone_id = c.timezoneID?.jv_toInt16 ?? m_timezone_id
            m_timezone = context.object(JVTimezone.self, primaryId: Int(m_timezone_id))
        }
        else if let c = change as? JVAgentWorktimeToggleChange {
            m_is_enabled = c.enable
            m_is_dirty = true
        }
        else if let c = change as? JVAgentWorktimeDayChange {
            storeLocalConfig(c.config, forDay: c.day)
            m_is_dirty = true
        }
        else if let c = change as? JVAgentWorktimeDirtyChange {
            m_is_dirty = c.isDirty
        }
    }
    
    private func unpackRemoteConfig(enabled: Bool, start: String, end: String) -> JVAgentWorktimeDayConfig {
        let sinceTime = extractTime(start)
        let tillTime = extractTime(end)

        return JVAgentWorktimeDayConfig(
            enabled: enabled,
            startHour: sinceTime.hour,
            startMinute: sinceTime.minute,
            endHour: tillTime.hour,
            endMinute: tillTime.minute
        )
    }
    
    private func extractTime(_ time: String) -> (hour: Int, minute: Int) {
        let parts = time.split(separator: ":")
        guard parts.count == 2 else { return (0, 0) }
        guard let hourSource = parts.first, let hour = Int(hourSource) else { return (0, 0) }
        guard let minuteSource = parts.last, let minute = Int(minuteSource) else { return (0, 0) }
        return (hour, minute)
    }
    
    private func storeLocalConfig(_ config: JVAgentWorktimeDayConfig, forDay day: JVAgentWorktimeDay) {
        let sinceHourArg, sinceMinuteArg, tillHourArg, tillMinuteArg: Int64
        if config.startHour + config.startMinute + config.endHour + config.endMinute > 0 {
            sinceHourArg = Int64(config.startHour << 24)
            sinceMinuteArg = Int64(config.startMinute << 16)
            tillHourArg = Int64(config.endHour << 8)
            tillMinuteArg = Int64(config.endMinute << 0)
        }
        else {
            sinceHourArg = Int64(09 << 24)
            sinceMinuteArg = Int64(00 << 16)
            tillHourArg = Int64(18 << 8)
            tillMinuteArg = Int64(00 << 0)
        }
        
        let enabledArg = Int64(Int(config.enabled ? 1 : 0) << 32)
        let source = Int64(enabledArg | sinceHourArg | sinceMinuteArg | tillHourArg | tillMinuteArg)

        switch day {
        case .monday:
            m_monConfig = source
        case .tuesday:
            m_tueConfig = source
        case .wednesday:
            m_wedConfig = source
        case .thursday:
            m_thuConfig = source
        case .friday:
            m_friConfig = source
        case .saturday:
            m_satConfig = source
        case .sunday:
            m_sunConfig = source
        }
    }
}

open class JVAgentWorktimeBaseChange: JVDatabaseModelChange {
    public var agentID: Int
        public init(agentID: Int) {
        self.agentID = agentID
        super.init()
    }
    
    required public init(json: JsonElement) {
        agentID = json["agent_id"].intValue
        super.init(json: json)
    }
}

public final class JVAgentWorktimeGeneralChange: JVDatabaseModelChange, Codable {
    public var agentID: Int
    public var timezoneID: Int
    public var enabled: Bool
    public var monEnabled: Bool
    public var monStart: String
    public var monEnd: String
    public var tueEnabled: Bool
    public var tueStart: String
    public var tueEnd: String
    public var wedEnabled: Bool
    public var wedStart: String
    public var wedEnd: String
    public var thuEnabled: Bool
    public var thuStart: String
    public var thuEnd: String
    public var friEnabled: Bool
    public var friStart: String
    public var friEnd: String
    public var satEnabled: Bool
    public var satStart: String
    public var satEnd: String
    public var sunEnabled: Bool
    public var sunStart: String
    public var sunEnd: String

    public override var primaryValue: Int {
        return agentID
    }
    
    public override var isValid: Bool {
        guard agentID > 0 else { return false }
        return true
    }
    
    required public init(json: JsonElement) {
        agentID = json["agent_id"].intValue
        timezoneID = json["timezone_id"].intValue
        enabled = json["work_time_enabled"].boolValue
        monEnabled = json["work_time"]["monday"].boolValue
        monStart = json["work_time"]["monday_start"].stringValue
        monEnd = json["work_time"]["monday_end"].stringValue
        tueEnabled = json["work_time"]["tuesday"].boolValue
        tueStart = json["work_time"]["tuesday_start"].stringValue
        tueEnd = json["work_time"]["tuesday_end"].stringValue
        wedEnabled = json["work_time"]["wednesday"].boolValue
        wedStart = json["work_time"]["wednesday_start"].stringValue
        wedEnd = json["work_time"]["wednesday_end"].stringValue
        thuEnabled = json["work_time"]["thursday"].boolValue
        thuStart = json["work_time"]["thursday_start"].stringValue
        thuEnd = json["work_time"]["thursday_end"].stringValue
        friEnabled = json["work_time"]["friday"].boolValue
        friStart = json["work_time"]["friday_start"].stringValue
        friEnd = json["work_time"]["friday_end"].stringValue
        satEnabled = json["work_time"]["saturday"].boolValue
        satStart = json["work_time"]["saturday_start"].stringValue
        satEnd = json["work_time"]["saturday_end"].stringValue
        sunEnabled = json["work_time"]["sunday"].boolValue
        sunStart = json["work_time"]["sunday_start"].stringValue
        sunEnd = json["work_time"]["sunday_end"].stringValue
        super.init(json: json)
    }
}

public final class JVAgentWorktimeTimezoneChange: JVAgentWorktimeBaseChange {
    public let timezoneID: Int?

    public override var primaryValue: Int {
        return agentID
    }
    
    public init(agentID: Int, timezoneID: Int?) {
        self.timezoneID = timezoneID
        super.init(agentID: agentID)
    }
    
    required public init(json: JsonElement) {
        abort()
    }
}

public final class JVAgentWorktimeToggleChange: JVAgentWorktimeBaseChange {
    public let enable: Bool

    public override var primaryValue: Int {
        return agentID
    }
    
    public init(agentID: Int, enable: Bool) {
        self.enable = enable
        super.init(agentID: agentID)
    }
    
    required public init(json: JsonElement) {
        abort()
    }
}

public final class JVAgentWorktimeDayChange: JVAgentWorktimeBaseChange {
    public let day: JVAgentWorktimeDay
    public let config: JVAgentWorktimeDayConfig
    
    public override var primaryValue: Int {
        return agentID
    }
    
    public init(agentID: Int, day: JVAgentWorktimeDay, config: JVAgentWorktimeDayConfig) {
        self.day = day
        self.config = config
        super.init(agentID: agentID)
    }
    
    required public init(json: JsonElement) {
        abort()
    }
}

public final class JVAgentWorktimeDirtyChange: JVAgentWorktimeBaseChange {
    public let isDirty: Bool

    public override var primaryValue: Int {
        return agentID
    }
    
    public init(agentID: Int, isDirty: Bool) {
        self.isDirty = isDirty
        super.init(agentID: agentID)
    }
    
    required public init(json: JsonElement) {
        abort()
    }
}
