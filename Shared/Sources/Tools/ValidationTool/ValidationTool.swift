//
//  ValidationTool.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation

protocol IValidationTool: AnyObject {
    func validatePassword(_ value: String) -> Error?
    func validateName(_ value: String) -> Error?
    func validateEmail(_ value: String, allowsEmpty: Bool) -> Error?
    func validatePhone(_ value: String) -> Error?
    func validateComment(_ value: String) -> Error?
}

final class ValidationTool: IValidationTool {
    typealias Validator = (NSTextCheckingResult) -> Bool
    
    init() {
    }
    
    func validatePassword(_ value: String) -> Error? {
        guard !value.isEmpty else { return ValidationError.missing }
        return nil
    }
    
    func validateName(_ value: String) -> Error? {
        guard value.count > 0 else { return ValidationError.missing }
        guard value.count < 128 else { return ValidationError.tooLong }
        return nil
    }
    
    func validateEmail(_ value: String, allowsEmpty: Bool) -> Error? {
        if value.isEmpty {
            return allowsEmpty ? nil : ValidationError.missing
        }
        else {
            guard value.count < 128 else { return ValidationError.tooLong }
            guard value.canBeConverted(to: .ascii) else { return ValidationError.invalid }
            
            if validate(value: value, type: .link, validator: { $0.url?.scheme == "mailto" }) {
                return nil
            }
            else {
                return ValidationError.invalid
            }
        }
    }
    
    func validatePhone(_ value: String) -> Error? {
        if value.isEmpty {
            return nil
        }
        else {
            guard value.count < 128 else { return ValidationError.tooLong }
            
            if validate(value: value, type: .phoneNumber, validator: nil) {
                return nil
            }
            else {
                return ValidationError.invalid
            }
        }
    }
    
    func validateComment(_ value: String) -> Error? {
        guard value.count < 128 else { return ValidationError.tooLong }
        return nil
    }
    
    private func validate(value: String, type: NSTextCheckingResult.CheckingType, validator: Validator?) -> Bool {
        guard let detector = try? NSDataDetector(types: type.rawValue) else { return true }
        
        let range = NSMakeRange(0, value.count)
        let matches = detector.matches(in: value, options: .anchored, range: range)
        guard matches.count == 1 else { return false }
        
        if let match = matches.first, match.range == range {
            return validator?(match) ?? true
        }
        else {
            return false
        }
    }
}
