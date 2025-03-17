//
//  JVIDispatcher_decl.swift
//  Pods
//
//  Created by Stan Potemkin on 12.04.2023.
//

import Foundation

protocol JVIDispatcher: AnyObject {
    func enqueueOperation(_ block: @escaping () -> Void)
}

extension OperationQueue: JVIDispatcher {
    func enqueueOperation(_ block: @escaping () -> Void) {
        addOperation {
            block()
        }
    }
}
