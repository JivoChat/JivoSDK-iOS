//
//  JsonPrivacyTool.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 27.03.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation

import JMCodingKit

final class JsonPrivacyTool {
    private struct Allowance {
        let rule: JsonPrivacyRule
        let isActive: Bool
    }
    
    private let enabled: Bool
    private let rules: [JsonPrivacyRule]
    
    private var currentJson = JsonElement()
    private var currentAllowance = [Allowance]()
    private var exclusiveRun = NSLock()
    
    init(enabled: Bool, rules: [JsonPrivacyRule]) {
        self.enabled = enabled
        self.rules = rules
    }
    
    /**
     The only point to perform some work on incoming json
     */
    func filter(json: JsonElement) -> JsonElement {
        exclusiveRun.lock()
        defer { exclusiveRun.unlock() }
        
        guard enabled else {
            return json
        }
        
        currentJson = json
        currentAllowance = rules.map { [resolver = resolveCondition] rule in Allowance(rule: rule, isActive: resolver(rule)) }
        return filterLevel(slice: currentJson, walkingPath: [])
    }
    
    /**
     Pick any object as is, except nesting ones (arrays and dicts)
     */
    private func filterLevel(slice: JsonElement, walkingPath: [String]) -> JsonElement {
        switch slice {
        case .array: return filterArray(array: slice, walkingPath: walkingPath)
        case .ordict: return filterOrdict(dict: slice, walkingPath: walkingPath)
        default: return slice
        }
    }
    
    /**
     Walk through an a array
     */
    private func filterArray(array: JsonElement, walkingPath: [String]) -> JsonElement {
        var result = [JsonElement]()
        for value in array.arrayValue {
            let securingPath = walkingPath + ["*"]
            let contentProvider = { [filter = filterLevel] in filter(value, securingPath) }
            let securedValue = retrieveSecuredValue(provider: contentProvider, path: securingPath)
            result.append(securedValue)
        }
        
        return JsonElement(result)
    }
    
    /**
     Walk through an ordict
     */
    private func filterOrdict(dict: JsonElement, walkingPath: [String]) -> JsonElement {
        var result = OrderedMap<String, JsonElement>()
        for (key, value) in dict.ordictValue {
            let securingPath = walkingPath + [key]
            let contentProvider = { [filter = filterLevel] in filter(value, securingPath) }
            let securedValue = retrieveSecuredValue(provider: contentProvider, path: securingPath)
            result.updateValue(securedValue, forKey: key)
        }
        
        return JsonElement(result)
    }
    
    /**
     Take rule and resolve it into allowance
     */
    private func resolveCondition(forRule rule: JsonPrivacyRule) -> Bool {
        guard
            let condition = rule.condition
            else { return true }
        
        var walking = currentJson
        for key in condition.path.split(separator: ".") {
            if let step = walking.has(key: String(key)) {
                walking = step
            }
            else {
                return false
            }
        }
        
        if walking == JsonElement(condition.value) {
            return true
        }
        else {
            return false
        }
    }
    
    /**
     Retrieve the modified value that corresponds to specific condition by active rule;
     Otherwise, it returns the original value
     */
    private func retrieveSecuredValue(provider: () -> JsonElement, path: [String]) -> JsonElement {
        for allowance in currentAllowance {
            guard allowance.isActive else {
                continue
            }
            
            for mask in allowance.rule.masks {
                guard mask.path == path.joined(separator: ".") else {
                    continue
                }
                
                switch mask.replacement {
                case .stars: return "[***]"
                case .trimming: return trimmedString(value: provider())
                case .custom(let block): return block(provider())
                }
            }
        }
        
        return provider()
    }
    
    /**
     Trim the string by keeping max of 2 leading symbols and 2 trailing symbols
     */
    private func trimmedString(value: JsonElement) -> JsonElement {
        guard let string = value.string else { return JsonElement("[...]") }
        guard string.count > 4 else { return JsonElement(string) }
        return JsonElement("[\(string.prefix(2))...\(string.suffix(2))]")
    }
}
