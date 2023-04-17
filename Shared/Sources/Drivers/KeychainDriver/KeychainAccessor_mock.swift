//
//  KeychainAccessorMock.swift
//  App
//
//  Created by Stan Potemkin on 09.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
@testable import Jivo

class KeychainAccessorMock: IKeychainAccessor {
    var hasObject = false
    
    var string: String? {
        didSet {
            hasObject = (string != nil)
        }
    }
    
    var number: Int? {
        didSet {
            hasObject = (string != nil)
        }
    }
    
    var date: Date? {
        didSet {
            hasObject = (string != nil)
        }
    }
    
    var data: Data? {
        didSet {
            hasObject = (string != nil)
        }
    }
    
    func withScope(_ scope: String?) -> IKeychainAccessor {
        return self
    }
    
    func erase() {
        string = nil
        number = nil
        date = nil
        data = nil
    }
}
