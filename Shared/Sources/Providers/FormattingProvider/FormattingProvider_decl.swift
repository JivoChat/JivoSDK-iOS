//
//  FormattingProvider.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 16/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import SwiftDate

protocol IFormattingProvider: AnyObject {
    var dateFormatter: DateFormatter { get }
    var calendar: Calendar { get }
    func format(date: Date, style: FormattingDateStyle) -> String
    func interval(between firstDate: Date, and secondDate: Date, style: FormattingIntervalStyle) -> String
    func isValidPhone(_ phone: String, countryCode: String?) -> Bool
    func format(phone: String, style: FormattingPhoneStyle, countryCode: String?, supportsFallback: Bool) -> String
    func format(size: Int64) -> String?
}

enum FormattingDateStyle {
    case lastMessageDate
    case dayHeader
    case messageTime
    case playbackTime
    case filterDate
    case taskFireDate
    case taskFireTime
    case taskFireDateTime
    case taskFireDateRelative
    case taskFireRelative
    case worktime
}

enum FormattingIntervalStyle {
    case sessionDuration
    case timeToTermination
}

enum FormattingPhoneStyle {
    case exchangable
    case plain
    case printable
    case decorative
}
