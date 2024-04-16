//
//  KeychainDriverDecl.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import KeychainSwift

protocol IKeychainDriver: AnyObject {
    var lastOperationFailure: OSStatus? { get }
    func retrieveAccessor(forToken token: KeychainToken) -> IKeychainAccessor
    func migrate(mapping: [(String, KeychainSwiftAccessOptions)])
    func scope(_ name: String) -> IKeychainDriver
    func clearNamespace(scopePrefix: String)
    func clearAll()
}
