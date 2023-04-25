//
//  JsonPrivacyRule.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 12.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

/**
 A rule means doing some replaces based on provided condition
 */
public struct JsonPrivacyRule {
    /**
     Condition is used to detect whether logic should apply the masks;
     condition means some path equals to some value (e.g. path="method" value="chat_message")
     */
    let condition: Condition?
    
    /**
     Masks to apply if condition is not presented, or condition resolves to be truth
     */
    let masks: [Mask]
    
    public init(condition: Condition?, masks: [Mask]) {
        self.condition = condition
        self.masks = masks
    }
}

extension JsonPrivacyRule {
    public struct Condition {
        let path: String
        let value: AnyHashable
        
        public init(path: String, value: AnyHashable) {
            self.path = path
            self.value = value
        }
    }
    
    public struct Mask {
        public enum Replacement { case stars, trimming, custom((JsonElement) -> JsonElement) }
        let path: String
        let replacement: Replacement
        
        public init(path: String, replacement: Replacement) {
            self.path = path
            self.replacement = replacement
        }
    }
}
