//
//  JivoSDK_Session.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 02.04.2023.
//

import Foundation

@available(*, deprecated)
@objc(JivoSDKSession)
public final class JivoSDKSession: NSObject, JVSessionDelegate {
    @objc(delegate)
    public var delegate: JivoSDKSessionDelegate? {
        didSet {
            Jivo.session.delegate = self
        }
    }
    
    @objc(setPreferredServer:)
    public func setPreferredServer(_ server: JivoSDKSessionServer) {
        Jivo.session.setPreferredServer(server.toNewAPI())
    }
    
    @objc(startUpWithChannelID:userToken:)
    public func startUp(channelID: String, userToken: String) {
        Jivo.session.startUp(channelID: channelID, userToken: userToken)
    }
    
    @available(*, deprecated, message: "Renamed to setClientInfo:")
    @objc(updateCustomData:)
    public func updateCustomData(_ data: JivoSDKSessionCustomData?) {
        Jivo.session.setContactInfo(data?.toNewAPI())
    }
    
    @objc(setClientInfo:)
    public func setClientInfo(_ info: JivoSDKSessionClientInfo?) {
        Jivo.session.setContactInfo(info?.toNewAPI())
    }
    
    @objc(setCustomData:)
    public func setCustomData(fields: [JivoSDKSessionCustomDataField]) {
        Jivo.session.setCustomData(fields: fields.map { $0.toNewAPI() })
    }
    
    @objc(shutDown)
    public func shutDown() {
        Jivo.session.shutDown()
    }
    
    public func jivoSession(updateUnreadCounter sdk: Jivo, number: Int) {
    }
}

@available(*, deprecated)
@objc(JivoSDKSessionDelegate)
public protocol JivoSDKSessionDelegate {
}

@available(*, deprecated)
@objc(JivoSDKSessionServer)
public enum JivoSDKSessionServer: Int {
    case auto
    case europe
    case russia
    case asia
}

@available(*, deprecated, renamed: "JivoSDKSessionClientInfo")
public class JivoSDKSessionCustomData: NSObject {
    let name: String?
    let email: String?
    let phone: String?
    let brief: String?
    
    @objc public init(name: String? = nil, email: String? = nil, phone: String? = nil, brief: String? = nil) {
        self.name = name?.jv_valuable
        self.email = email?.jv_valuable
        self.phone = phone?.jv_valuable
        self.brief = brief?.jv_valuable
        
        super.init()
    }
}

@available(*, deprecated)
@objc(JivoSDKSessionClientInfo)
public class JivoSDKSessionClientInfo: NSObject {
    let name: String?
    let email: String?
    let phone: String?
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
    
    public var hasAnyField: Bool {
        return jv_not(collectSignificantFields.joined().isEmpty)
    }
    
    public var hasAllFields: Bool {
        return (collectAllFields.count == collectSignificantFields.count)
    }
    
    public override var debugDescription: String {
        return "JivoSDKSessionClientInfo object {\nname: \(String(describing: name));\nemail: \(String(describing: email));\nphone: \(String(describing: phone));\nbrief: \(String(describing: brief))\n}"
    }
    
    private var collectAllFields: [String?] {
        return [name, email, phone]
    }
    
    private var collectSignificantFields: [String] {
        return collectAllFields.jv_flatten().compactMap(\.jv_valuable)
    }
}

@available(*, deprecated)
@objc(JivoSDKSessionCustomDataField)
public class JivoSDKSessionCustomDataField: NSObject {
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

fileprivate extension JivoSDKSessionServer {
    func toNewAPI() -> JVSessionServer {
        switch self {
        case .auto:
            return .auto
        case .europe:
            return .europe
        case .russia:
            return .russia
        case .asia:
            return .asia
        }
    }
}

fileprivate extension JivoSDKSessionCustomData {
    func toNewAPI() -> JVSessionContactInfo {
        return JVSessionContactInfo(name: name, email: email, phone: phone, brief: brief)
    }
}

fileprivate extension JivoSDKSessionClientInfo {
    func toNewAPI() -> JVSessionContactInfo {
        return JVSessionContactInfo(name: name, email: email, phone: phone, brief: brief)
    }
}

fileprivate extension JivoSDKSessionCustomDataField {
    func toNewAPI() -> JVSessionCustomDataField {
        return JVSessionCustomDataField(title: title, key: key, content: content, link: link)
    }
}
