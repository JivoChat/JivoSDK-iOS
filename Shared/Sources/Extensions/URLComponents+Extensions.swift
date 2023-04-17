//
//  URLComponents+Extensions.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension URLComponents {
    mutating func jv_setQuery(mapping: [String: String?]) {
        let escapingSet = CharacterSet.urlQueryAllowed
            .subtracting(CharacterSet(charactersIn: "+"))
        
        percentEncodedQueryItems = mapping.compactMap { key, object in
            let name = key.addingPercentEncoding(withAllowedCharacters: escapingSet) ?? key
            let value = object?.addingPercentEncoding(withAllowedCharacters: escapingSet) ?? object
            
            if let value = value {
                return URLQueryItem(name: name, value: value)
            }
            else {
                return nil
            }
        }
    }
}
