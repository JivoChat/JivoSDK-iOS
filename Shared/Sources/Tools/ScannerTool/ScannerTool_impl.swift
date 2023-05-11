//
//  ScannerTool_impl.swift
//
//  Created by Stan Potemkin on 24.04.2023.
//

import Foundation

final class ScannerTool: IScannerTool {
    private let scanner: Scanner
    
    init(source: String) {
        scanner = Scanner(string: source)
    }
    
    @discardableResult
    func scan(till string: String) -> String? {
        var result = String()
        
        if #available(iOS 13.0, *) {
            if let scanned = scanner.scanUpToString(string) {
                result.append(scanned)
            }
        }
        else {
            var scanned: NSString?
            
            scanner.scanUpTo(string, into: &scanned)
            if let scanned = scanned {
                result.append(scanned as String)
            }
        }
        
        return result.jv_valuable
    }
    
    @discardableResult
    func scan(over string: String) -> String? {
        var result = String()
        
        if #available(iOS 13.0, *) {
            if let scanned = scanner.scanUpToString(string) {
                result.append(scanned)
            }
            
            if let scanned = scanner.scanString(string) {
                result.append(scanned)
            }
        }
        else {
            var scanned: NSString?
            
            scanner.scanUpTo(string, into: &scanned)
            if let scanned = scanned {
                result.append(scanned as String)
            }
            
            scanner.scanString(string, into: &scanned)
            if let scanned = scanned {
                result.append(scanned as String)
            }
        }
        
        return result
    }
}
