//
//  JVSessionContactInfo.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 You may want to assign contact info to user
 */
@objc(JVSessionContactInfo)
public class JVSessionContactInfo: NSObject {
    /// Client name
    let name: String?
    
    /// Client e-mail
    let email: String?
    
    /// Client phone number
    let phone: String?
    
    /// Additional information about the client in any form
    let brief: String?
    
    @objc public init(name: String? = nil, email: String? = nil, phone: String? = nil, brief: String? = nil) {
        self.name = name?.jv_valuable
        self.email = email?.jv_valuable
        self.phone = phone?.jv_valuable
        self.brief = brief?.jv_valuable
        super.init()
    }
    
    @objc public override init() {
        self.name = nil
        self.email = nil
        self.phone = nil
        self.brief = nil
        super.init()
    }
}

extension JVSessionContactInfo {
    var hasAnyField: Bool {
        if let _ = email?.jv_valuable { return true }
        if let _ = phone?.jv_valuable { return true }
        return false
    }
    
    var hasAllFields: Bool {
        return (collectAllFields.count == collectSignificantFields.count)
    }
    
    public override var debugDescription: String {
        return "ContactInfo object {\nname: \(String(describing: name));\nemail: \(String(describing: email));\nphone: \(String(describing: phone));\nbrief: \(String(describing: brief))\n}"
    }
    
    private var collectAllFields: [String?] {
        return [name, email, phone]
    }
    
    private var collectSignificantFields: [String] {
        return collectAllFields.jv_flatten().compactMap(\.jv_valuable)
    }
}
