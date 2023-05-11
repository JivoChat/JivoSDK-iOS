//
//  JVPureParserTool.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 01.12.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
import PureParser

protocol JVIPureParserTool: AnyObject {
    func assign(variable name: String, value: String?)
    func activate(alias: String, _ rule: Bool)
    func execute(_ formula: String, collapseSpaces: Bool) -> String
}

final class JVPureParserTool: JVIPureParserTool {
    private let parser = PureParser()
    
    init() {
    }
    
    func assign(variable name: String, value: String?) {
        parser.assign(variable: name, value: value)
    }
    
    func activate(alias: String, _ rule: Bool) {
        parser.activate(alias: alias, rule)
    }
    
    func execute(_ formula: String, collapseSpaces: Bool) -> String {
        return parser.execute(formula, collapseSpaces: collapseSpaces, resetOnFinish: true)
    }
}
