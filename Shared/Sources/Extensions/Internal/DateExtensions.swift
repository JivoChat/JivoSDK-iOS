//
//  DateExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 11/07/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation

extension Date {
    func withoutTime() -> Date {
        let components = JVActiveLocale().calendar.dateComponents([.year, .month, .day], from: self)
        return JVActiveLocale().calendar.date(from: components) ?? Date()
    }
    
    func roundBySeconds() -> Date {
        return dateBySet([.nanosecond: 0]) ?? self
    }
    
    func addingDays(_ number: Int) -> Date? {
        return JVActiveLocale().calendar.date(byAdding: .day, value: number, to: self)
    }
    
    func addingYears(_ number: Int) -> Date? {
        return JVActiveLocale().calendar.date(byAdding: .year, value: number, to: self)
    }
    
    func startOfDay(calendar: Calendar) -> Date? {
        return calendar.date(bySettingHour: 0, minute: 0, second: 0, of: self)
    }

    func endOfDay(calendar: Calendar) -> Date? {
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: self)
    }

    func distance(to another: Date) -> Int? {
        return JVActiveLocale().calendar.dateComponents([Calendar.Component.day], from: self, to: another).day
    }
    
    func isOlder(then lifetime: TimeInterval) -> Bool {
        let diff = Date().timeIntervalSince(self)
        return (diff > lifetime)
    }
}
