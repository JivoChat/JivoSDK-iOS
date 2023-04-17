//
//  StringExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 08/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

public extension String {
    public func jv_parseDateUsingFullFormat() -> Date? {
        let dateParser = DateFormatter()
        dateParser.locale = JVActiveLocale()
        dateParser.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateParser.timeZone = TimeZone(identifier: "GMT")
        
        if let downToSeconds = split(separator: ".").first {
            return dateParser.date(from: String(downToSeconds))
        }
        else {
            return dateParser.date(from: self)
        }
    }
}
