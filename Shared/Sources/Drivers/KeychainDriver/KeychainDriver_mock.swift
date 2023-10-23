//
//  KeychainDriverMock.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import KeychainSwift
@testable import App

class KeychainDriverMock: IKeychainDriver {
    var lastOperationFailure: OSStatus? {
        fatalError()
    }
    
    func retrieveAccessor(forToken token: KeychainToken) -> IKeychainAccessor {
        fatalError()
    }
    
    func migrate(mapping: [(String, KeychainSwiftAccessOptions)]) {
        fatalError()
    }
    
    func clearAll() {
        fatalError()
    }
}
