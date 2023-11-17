//
//  JVDispatchThreadMock.swift
//  Pods
//
//  Created by Stan Potemkin on 08.03.2023.
//

import Foundation
@testable import App

open class JVDispatchThreadMock: JVIDispatchThread {
    public init() {
    }
    
    public func async(block: @escaping () -> Void) {
        fatalError()
    }
    
    public func sync(block: @escaping () -> Void) {
        fatalError()
    }
    
    public func addOperation(_ block: @escaping () -> Void) {
        fatalError()
    }
    
    public func stop() {
    }
}
