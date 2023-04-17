//
//  ConditionalFlow.swift
//  App
//
//  Created by Stan Potemkin on 27.10.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

final class ConditionalFlow<Value: Equatable> {
    private let initialValue: Value
    
    private(set) var currentValue: Value
    
    init(initialValue: Value) {
        self.initialValue = initialValue
        self.currentValue = initialValue
    }
    
    func turn(to: Value) {
        currentValue = to
    }
    
    func turn(from: Value, to: Value) {
        guard from == currentValue
        else {
            return
        }
        
        currentValue = to
    }
    
    func equals(value: Value) -> Bool {
        return (value == currentValue)
    }
    
    func reset() {
        currentValue = initialValue
    }
}
