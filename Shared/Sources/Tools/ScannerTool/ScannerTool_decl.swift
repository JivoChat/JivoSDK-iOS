//
//  ScannerTool_decl.swift
//
//  Created by Stan Potemkin on 24.04.2023.
//

import Foundation

protocol IScannerTool: AnyObject {
    @discardableResult
    func scan(till string: String) -> String?
    
    @discardableResult
    func scan(over string: String) -> String?
}
