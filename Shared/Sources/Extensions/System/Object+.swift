//
//  ObjectExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 11/12/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import CoreData

protocol JVValidatable {
    var jv_isValid: Bool { get }
}

extension NSManagedObject: JVValidatable {
    var jv_isValid: Bool {
        return true
    }
}

func jv_validate<T: JVValidatable>(_ object: T?) -> T? {
    guard let object = object else { return nil }
    return object.jv_isValid ? object : nil
}
