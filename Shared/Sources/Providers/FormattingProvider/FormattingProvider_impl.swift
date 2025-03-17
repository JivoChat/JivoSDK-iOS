//
//  FormattingProvider.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 16/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import SwiftDate

#if canImport(libPhoneNumber)
import libPhoneNumber
#elseif canImport(libPhoneNumber_iOS)
import libPhoneNumber_iOS
#endif

final class FormattingProvider: IFormattingProvider {
    private let preferencesDriver: IPreferencesDriver
    private let localeProvider: JVILocaleProvider
    private let systemLocale: Locale
    let dateFormatter = DateFormatter()
    private let ampmFormatter = DateFormatter()
    private let byteFormatter = ByteCountFormatter()
    private let phoneNumberKit = NBPhoneNumberUtil.sharedInstance()!
    private(set) var calendar = Calendar.autoupdatingCurrent
    
    init(preferencesDriver: IPreferencesDriver,
         localeProvider: JVILocaleProvider,
         systemLocale: Locale
    ) {
        self.preferencesDriver = preferencesDriver
        self.localeProvider = localeProvider
        self.systemLocale = systemLocale

        ampmFormatter.dateStyle = .none
        ampmFormatter.timeStyle = .short
    }

    func format(date: Date, style: FormattingDateStyle) -> String {
        dateFormatter.calendar = calendar
        dateFormatter.locale = systemLocale
        
        switch style {
        case .lastMessageDate where date.isToday:
            dateFormatter.dateFormat = needsAMPM ? "h:mm a" : "H:mm"
            dateFormatter.doesRelativeDateFormatting = false

        case .lastMessageDate where date.isYesterday:
            dateFormatter.dateStyle = .medium
            dateFormatter.doesRelativeDateFormatting = true

        case .lastMessageDate:
            dateFormatter.dateFormat = "d MMM"
            dateFormatter.doesRelativeDateFormatting = false

        case .dayHeader:
            dateFormatter.dateFormat = "d MMMM"
            dateFormatter.doesRelativeDateFormatting = false

        case .messageTime:
            dateFormatter.dateFormat = needsAMPM ? "h:mm a" : "H:mm"
            dateFormatter.doesRelativeDateFormatting = false
            
        case .playbackTime:
            dateFormatter.dateFormat = "m:ss"
            dateFormatter.doesRelativeDateFormatting = false
            
        case .filterDate:
            dateFormatter.dateFormat = "d.MM.yy"
            dateFormatter.doesRelativeDateFormatting = false

        case .taskFireDate:
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            dateFormatter.doesRelativeDateFormatting = false

        case .taskFireTime:
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            dateFormatter.doesRelativeDateFormatting = false
            
        case .taskFireDateTime:
            dateFormatter.dateFormat = "d MMM, " + (needsAMPM ? "h:mm a" : "H:mm")
            dateFormatter.doesRelativeDateFormatting = false
            
        case .taskFireRelative where date.isToday:
            dateFormatter.dateFormat = needsAMPM ? "h:mm a" : "H:mm"
            dateFormatter.doesRelativeDateFormatting = true

        case .taskFireRelative where date.year == Date().year:
            dateFormatter.dateFormat = "d MMM"
            dateFormatter.doesRelativeDateFormatting = false

        case .taskFireRelative:
            dateFormatter.dateFormat = "d MMM yyyy"
            dateFormatter.doesRelativeDateFormatting = false

        case .worktime:
            dateFormatter.dateFormat = needsAMPM ? "h:mm a" : "H:mm"
            dateFormatter.doesRelativeDateFormatting = false
        }
        
        return dateFormatter.string(from: date)
    }

    func interval(between firstDate: Date, and secondDate: Date, style: FormattingIntervalStyle) -> String {
        calendar.locale = systemLocale
        
        switch style {
        case .sessionDuration:
            let formatter = DateComponentsFormatter()
            formatter.calendar = calendar
            formatter.allowedUnits = [.hour, .minute]
            formatter.zeroFormattingBehavior = [.dropAll]
            formatter.unitsStyle = .short

            let result: String
            if secondDate.timeIntervalSince(firstDate) < 60 {
                let minuteDate = firstDate.addingTimeInterval(60)
                result = "< " + (formatter.string(from: firstDate, to: minuteDate) ?? "")
            }
            else if secondDate.timeIntervalSince(firstDate) > 86400 {
                let dayDate = firstDate.addingTimeInterval(86400)
                result = "> " + (formatter.string(from: firstDate, to: dayDate) ?? "")
            }
            else {
                result = formatter.string(from: firstDate, to: secondDate) ?? ""
            }

            return result.jv_unbreakable()

        case .timeToTermination:
            let formatter = DateComponentsFormatter()
            formatter.calendar = calendar
            formatter.allowedUnits = [.minute, .second]
            formatter.zeroFormattingBehavior = [.pad]
            formatter.unitsStyle = .positional

            let result = formatter.string(from: firstDate, to: max(firstDate, secondDate)) ?? ""
            return result.jv_unbreakable()
        }
    }

    func isValidPhone(_ phone: String, countryCode: String?) -> Bool {
        let allLocales = [systemLocale] + localeProvider.availableLocales
        for locale in allLocales {
            let region = countryCode ?? locale.jv_countryID ?? locale.jv_langId
            guard let value = try? phoneNumberKit.parse(phone, defaultRegion: region) else { continue }
            guard phoneNumberKit.isPossibleNumber(value) else { continue }
            return true
        }

        guard let defaultCode = phoneNumberKit.countryCodeByCarrier() else { return false }
        guard let value = try? phoneNumberKit.parse(phone, defaultRegion: defaultCode) else { return false }
        guard phoneNumberKit.isPossibleNumber(value) else { return false }
        return true
    }

    func format(phone: String, style: FormattingPhoneStyle, countryCode: String?, supportsFallback: Bool) -> String {
        guard !phone.isEmpty else {
            return String()
        }
        
        guard let digits = phoneNumberKit.normalizeDigitsOnly(phone) else {
            return phone
        }
        
        if style == .printable, phone.hasPrefix("+") {
            return phone
        }
        else if digits.count > 10, let result = tryFormat(phone: "+\(digits)", style: style, countryCode: countryCode) {
            return result
        }
        else if let result = tryFormat(phone: digits, style: style, countryCode: countryCode) {
            return result
        }
        else {
            let defaultCode = phoneNumberKit.countryCodeByCarrier()
            return tryFormat(phone: digits, style: style, countryCode: defaultCode) ?? digits
        }
    }

    func format(size: Int64) -> String? {
        return size < 0 ? nil : byteFormatter.string(fromByteCount: size)
    }

    private func tryFormat(phone: String, style: FormattingPhoneStyle, countryCode: String?) -> String? {
        let allLocales: [Locale] = [Locale.current, systemLocale] /*+ localeProvider.availableLocales*/
        for locale in allLocales {
            let region = countryCode ?? locale.jv_countryID ?? locale.jv_langId
            guard let value = try? phoneNumberKit.parse(phone, defaultRegion: region) else { continue }
            guard phoneNumberKit.isPossibleNumber(value) else { continue }
            
            do {
                let result = try format(number: value, style: style)
                return result
            }
            catch {
                continue
            }
        }

        return nil
    }

    private var needsAMPM: Bool {
        ampmFormatter.locale = systemLocale
        
        let format = ampmFormatter.string(from: Date())
        if format.contains(ampmFormatter.amSymbol) { return true }
        if format.contains(ampmFormatter.pmSymbol) { return true }
        return false
    }

    private func format(number: NBPhoneNumber, style: FormattingPhoneStyle) throws -> String {
        switch style {
        case .exchangable:
            return try phoneNumberKit.format(number, numberFormat: .E164).replacingOccurrences(of: "+", with: String())
        case .plain:
            return try phoneNumberKit.format(number, numberFormat: .E164)
        case .printable, .decorative:
            return try phoneNumberKit.format(number, numberFormat: .INTERNATIONAL)
        }
    }
}
