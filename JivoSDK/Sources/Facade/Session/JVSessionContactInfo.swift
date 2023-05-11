//
//  JVSessionContactInfo.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Holds the contact info of a client
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
        self.name = name
        self.email = email
        self.phone = phone
        self.brief = brief
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
        return jv_not(collectSignificantFields.joined().isEmpty)
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
