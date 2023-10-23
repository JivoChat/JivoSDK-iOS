//
//  FormattingProvider.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 16/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import SwiftDate
import libPhoneNumber_iOS
@testable import App

class FormattingProviderMock: IFormattingProvider {
    let dateFormatter = DateFormatter()
    let calendar = Calendar.autoupdatingCurrent
    
    init() {
    }

    func format(date: Date, style: FormattingDateStyle) -> String {
        fatalError()
    }

    func interval(between firstDate: Date, and secondDate: Date, style: FormattingIntervalStyle) -> String {
        fatalError()
    }

    func isValidPhone(_ phone: String, countryCode: String?) -> Bool {
        fatalError()
    }

    func format(phone: String, style: FormattingPhoneStyle, countryCode: String?, supportsFallback: Bool) -> String {
        fatalError()
    }

    func format(size: Int64) -> String? {
        fatalError()
    }
}
