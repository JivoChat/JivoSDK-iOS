//
//  RepeatingRequest.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 05.08.2021.
//

import Foundation

class RepeatingRequest {
    private(set) var startDate = Date()
    var repeatsCount: Int {
        return repeatingBlock?.repeatsCount ?? 0
    }
    
    private var repeatingBlock: RepeatingBlock?
    
    init(repeatsCountLimit: Int, _ request: @escaping (RepeatingRequest) -> Void) {
        repeatingBlock = RepeatingBlock(repeatsCountLimit: repeatsCountLimit) { [weak self] repeatingBlock in
            guard let self = self else { return }
            request(self)
        }
    }
}

extension RepeatingRequest: Performing {
    func perform() {
        repeatingBlock?.perform()
    }
}
