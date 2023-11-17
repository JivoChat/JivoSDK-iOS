//
//  FormattingProviderUnit.swift
//  TestFlow-Units
//
//  Created by Yulia on 15.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import XCTest
import Foundation
@testable import App

final class FormattingProviderUnit: XCTestCase {
    
    func buildFormattingProvider(locale: Locale) -> FormattingProvider {
        let preferencesDriver = PreferencesDriver(storage: .standard, namespace: "test1")
        let localeProvider = JVLocaleProvider(containingBundle: Bundle.main, activeLocale: locale)
        return FormattingProvider(preferencesDriver: preferencesDriver,
                                  localeProvider: localeProvider,
                                  systemLocale: locale)
    }
    
    func testSizeFormatting() {
        let sut = buildFormattingProvider(locale: Locale(identifier: "ru_RU"))
        
        let language = Bundle.main.preferredLocalizations.first
        
        if language == "en" {
            XCTAssertEqual(sut.format(size: 6512), Optional("7 KB"))
            XCTAssertEqual(sut.format(size: 6500), Optional("7 KB"))
            XCTAssertEqual(sut.format(size: 6499), Optional("6 KB"))
            XCTAssertEqual(sut.format(size: 6144), Optional("6 KB"))
            XCTAssertEqual(sut.format(size: 6143), Optional("6 KB"))
            XCTAssertEqual(sut.format(size: 6001), Optional("6 KB"))
            XCTAssertEqual(sut.format(size: 6000), Optional("6 KB"))
            XCTAssertEqual(sut.format(size: 5999), Optional("6 KB"))
            XCTAssertEqual(sut.format(size: 61)!, "61 bytes")
            XCTAssertEqual(sut.format(size: 0), "Zero KB")
            XCTAssertEqual(sut.format(size: 4294967296)!, "4.29 GB")
            XCTAssertEqual(sut.format(size: -1), nil)
        } else if language == "ru" {
            XCTAssertEqual(sut.format(size: 6512), Optional("7 КБ"))
            XCTAssertEqual(sut.format(size: 6500), Optional("7 КБ"))
            XCTAssertEqual(sut.format(size: 6499), Optional("6 КБ"))
            XCTAssertEqual(sut.format(size: 6144), Optional("6 КБ"))
            XCTAssertEqual(sut.format(size: 6143), Optional("6 КБ"))
            XCTAssertEqual(sut.format(size: 6001), Optional("6 КБ"))
            XCTAssertEqual(sut.format(size: 6000), Optional("6 КБ"))
            XCTAssertEqual(sut.format(size: 5999), Optional("6 КБ"))
            XCTAssertEqual(sut.format(size: 61)!, "61 байт")
            XCTAssertEqual(sut.format(size: 4294967296)!, "4.29 ГБ")
            XCTAssertEqual(sut.format(size: -1), nil)
        }
    }
    
    func testIntervalFormatting() {
        var sut = buildFormattingProvider(locale: Locale(identifier: "ru_RU"))
        var date: Date = .init(year: 2022, month: 9, day: 26, hour: 7, minute: 1, second: 3)
        
        XCTAssertEqual(sut.interval(between: date,
                                    and: date.addingTimeInterval(30),
                                    style: .timeToTermination),
                       "00:30")
        
        XCTAssertEqual(sut.interval(between: date.addingTimeInterval(30),
                                    and: date,
                                    style: .timeToTermination),
                       "00:00")
        
        XCTAssertEqual(sut.interval(between: date,
                                    and: date,
                                    style: .sessionDuration),
                       "< 1 мин")
        
        XCTAssertEqual(sut.interval(between: date,
                                    and: date.addingTimeInterval(-30),
                                    style: .sessionDuration),
                       "< 1 мин")
        
        XCTAssertEqual(sut.interval(between: date,
                                    and: date.addingTimeInterval(30),
                                    style: .sessionDuration),
                       "< 1 мин")
        
        XCTAssertEqual(sut.interval(between: date,
                                    and: date.addingTimeInterval(1000),
                                    style: .sessionDuration),
                       "16 мин")
        
        XCTAssertEqual(sut.interval(between: date,
                                    and: date.addingTimeInterval(86401),
                                    style: .sessionDuration),
                       "> 24 ч")
        
        sut = buildFormattingProvider(locale: Locale(identifier: "en_EN"))
        date = .init(year: 2023, month: 2, day: 24, hour: 12, minute: 12, second: 12)
        
        XCTAssertEqual(sut.interval(between: date,
                                    and: date.addingTimeInterval(30),
                                    style: .timeToTermination),
                       "00:30")
        
        XCTAssertEqual(sut.interval(between: date.addingTimeInterval(30),
                                    and: date,
                                    style: .timeToTermination),
                       "00:00")
        
        XCTAssertEqual(sut.interval(between: date,
                                    and: date,
                                    style: .sessionDuration),
                       "< 1 min")
        
        XCTAssertEqual(sut.interval(between: date,
                                    and: date.addingTimeInterval(-30),
                                    style: .sessionDuration),
                       "< 1 min")
        
        XCTAssertEqual(sut.interval(between: date,
                                    and: date.addingTimeInterval(30),
                                    style: .sessionDuration),
                       "< 1 min")
        
        XCTAssertEqual(sut.interval(between: date,
                                    and: date.addingTimeInterval(1000),
                                    style: .sessionDuration),
                       "16 min")
        
        XCTAssertEqual(sut.interval(between: date,
                                    and: date.addingTimeInterval(86401),
                                    style: .sessionDuration),
                       "> 24 hr")
    }
    
    func testDateFormatting() {
        var sut = buildFormattingProvider(locale: Locale(identifier: "ru_RU"))
        var date: Date = .init(year: 2022, month: 3, day: 20, hour: 3, minute: 26, second: 34)
        
        XCTAssertEqual(sut.format(date: date, style: .lastMessageDate), "20 марта")
        XCTAssertEqual(sut.format(date: date, style: .dayHeader), "20 марта")
        XCTAssertEqual(sut.format(date: date, style: .messageTime), "6:26")
        XCTAssertEqual(sut.format(date: date, style: .playbackTime), "26:34")
        XCTAssertEqual(sut.format(date: date, style: .filterDate), "20.03.22")
        XCTAssertEqual(sut.format(date: date, style: .taskFireDate), "20.03.2022")
        XCTAssertEqual(sut.format(date: date, style: .taskFireTime), "06:26")
        XCTAssertEqual(sut.format(date: date, style: .taskFireDateTime), "20 марта, 6:26")
        XCTAssertEqual(sut.format(date: date, style: .taskFireRelative), "20 марта 2022")
        XCTAssertEqual(sut.format(date: date, style: .messageTime), "6:26")
        
        sut = buildFormattingProvider(locale: Locale(identifier: "en_EN"))
        date = .init(year: 2022, month: 8, day: 26, hour: 0, minute: 0, second: 0)
        
        XCTAssertEqual(sut.format(date: date, style: .lastMessageDate), "26 Aug")
        XCTAssertEqual(sut.format(date: date, style: .dayHeader), "26 August")
        XCTAssertEqual(sut.format(date: date, style: .messageTime), "3:00")
        XCTAssertEqual(sut.format(date: date, style: .playbackTime), "0:00")
        XCTAssertEqual(sut.format(date: date, style: .filterDate), "26.08.22")
        XCTAssertEqual(sut.format(date: date, style: .taskFireDate), "8/26/22")
        XCTAssertEqual(sut.format(date: date, style: .taskFireTime), "03:00")
        XCTAssertEqual(sut.format(date: date, style: .taskFireDateTime), "26 Aug, 3:00")
        XCTAssertEqual(sut.format(date: date, style: .taskFireRelative), "26 Aug 2022")
        XCTAssertEqual(sut.format(date: date, style: .messageTime), "3:00")
    }
}
