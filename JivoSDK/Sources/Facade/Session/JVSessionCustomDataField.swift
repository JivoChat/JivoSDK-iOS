//
//  JVSessionCustomDataField.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

@objc(JVSessionCustomDataField)
public class JVSessionCustomDataField: NSObject {
    let title: String?
    let key: String?
    let content: String
    let link: String?
    
    @objc public init(title: String? = nil, key: String? = nil, content: String = String(), link: String? = nil) {
        self.title = title
        self.key = key
        self.content = content
        self.link = link
        super.init()
    }
}
