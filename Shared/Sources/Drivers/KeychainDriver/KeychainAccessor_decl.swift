//
//  KeychainAccessorDecl.swift
//  App
//
//  Created by Stan Potemkin on 09.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

protocol IKeychainAccessor: AnyObject {
    var hasObject: Bool { get }
    var string: String? { get set }
    var number: Int? { get set }
    var date: Date? { get set }
    var data: Data? { get set }
    func withScope(_ scope: String?) -> IKeychainAccessor
    func erase()
}
