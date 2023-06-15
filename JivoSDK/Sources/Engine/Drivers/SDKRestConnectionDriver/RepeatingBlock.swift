//
//  RepeatingBlock.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 05.08.2021.
//

import Foundation

class RepeatingBlock {
    private(set) var repeatsCount: Int = 0
    
    private let block: (RepeatingBlock) -> Void
    private let repeatsCountLimit: Int
    
    init(repeatsCountLimit: Int, _ block: @escaping (RepeatingBlock) -> Void) {
        self.block = block
        self.repeatsCountLimit = repeatsCountLimit
    }
}

extension RepeatingBlock: Performing {
    func perform() {
        if repeatsCount < repeatsCountLimit {
            block(self)
            repeatsCount += 1
        }
    }
}
