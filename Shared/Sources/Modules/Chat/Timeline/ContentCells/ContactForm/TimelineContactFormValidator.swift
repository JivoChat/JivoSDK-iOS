//
//  TimelineContactFormValidator.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 07.02.2023.
//

import Foundation

#if canImport(JivoFoundation)
import JivoFoundation
#endif

protocol TimelineContactFormValidator {
    func isValid(input: String) -> Bool
}

struct TimelineContactFormDefaultValidator: TimelineContactFormValidator {
    func isValid(input: String) -> Bool {
        return jv_not(input.isEmpty)
    }
}

struct TimelineContactFormPhoneValidator: TimelineContactFormValidator {
    func isValid(input: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^\\+?\\d{5,}$")
            let range = NSMakeRange(0, input.utf16.count)
            let numberOfMatches = regex.numberOfMatches(in: input, range: range)
            return (numberOfMatches > 0)
        }
        catch {
            return jv_not(input.isEmpty)
        }
    }
}

struct TimelineContactFormEmailValidator: TimelineContactFormValidator {
    func isValid(input: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: #"^.+@.+\..+$"#, options: [])
            let range = NSMakeRange(0, input.utf16.count)
            let matches = regex.matches(in: input, options: [], range: range)
            let status = jv_not(matches.isEmpty)
            return status
        }
        catch {
            return false
        }
    }
}
