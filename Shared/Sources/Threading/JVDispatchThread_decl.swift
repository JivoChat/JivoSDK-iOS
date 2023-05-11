//
//  JVDispatchThreadDecl.swift
//  Pods
//
//  Created by Stan Potemkin on 08.03.2023.
//

import Foundation

protocol JVIDispatchThread: AnyObject, JVIDispatcher {
    func async(block: @escaping () -> Void)
    func sync(block: @escaping () -> Void)
    func stop()
}
