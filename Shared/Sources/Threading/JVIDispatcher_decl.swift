//
//  JVIDispatcher_decl.swift
//  Pods
//
//  Created by Stan Potemkin on 12.04.2023.
//

import Foundation

public protocol JVIDispatcher: AnyObject {
    func addOperation(_ block: @escaping () -> Void)
}

extension OperationQueue: JVIDispatcher {
}
