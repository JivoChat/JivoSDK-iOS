//
//  FormattingProviderExt.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 14.12.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

extension IFormattingProvider {
    func format(worktime meta: JVAgentWorktimeDayMeta?, anotherDay: Bool) -> String {
        guard let meta = meta else {
            return String()
        }
        
        let targetIndex = meta.day.systemIndex
        guard let weekdayDate = calendar.date(bySetting: .weekday, value: targetIndex, of: Date()) else {
            return String()
        }
        
        let hour = meta.config.startHour
        let minute = meta.config.startMinute
        guard let targetDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: weekdayDate) else {
            return String()
        }
        
        dateFormatter.calendar = calendar
        dateFormatter.locale = JVActiveLocale()
        dateFormatter.dateFormat = (anotherDay ? "HH:mm (cccc)" : "HH:mm")

        return dateFormatter.string(from: targetDate)
    }
}
