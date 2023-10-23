//
//  JSONExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 05/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JsonElement {
    var status: JsonElement {
        return self
    }
    
    func parse<T: JVDatabaseModelChange>(force: Bool = false) -> T? {
        if exists(withValue: true) {
            let change = T(json: self)
            return (change.isValid || force ? change : nil)
        }
        else {
            return nil
        }
    }
    
    func parse<T: JVDatabaseModelChange>(model: T.Type, force: Bool = false) -> T? {
        if exists(withValue: true) {
            let change = T(json: self)
            return (change.isValid || force ? change : nil)
        }
        else {
            return nil
        }
    }
    
    func parseList<T: JVDatabaseModelChange>() -> [T]? {
        return array?.map { T(json: $0) }
    }
}
