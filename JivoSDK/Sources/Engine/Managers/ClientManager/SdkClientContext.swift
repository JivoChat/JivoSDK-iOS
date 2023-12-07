//
//  SdkClientContext.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 12.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

protocol ISdkClientContext: AnyObject, IBaseUserContext {
    var eventSignal: JVBroadcastTool<SdkClientContextEvent> { get }
    var clientId: String? { get set }
    var clientNumber: Int? { get }
    var clientHash: Int { get }
    var personalNamespace: String? { get set }
    var licensing: SdkClientLicensing? { get set }
    var contactInfo: JVSessionContactInfo { get set }
    func reset()
}

enum SdkClientContextEvent {
    case clientIdChanged(String?)
    case personalNamespaceChanged(String?)
    case licenseStateUpdated(SdkClientLicensing?)
}

struct SdkClientAccountConfig: Equatable, Codable, Hashable {
    let siteId: Int
    let channelId: String
}

enum SdkClientLicensing {
    case unlicensed
    case licensed
}

final class SdkClientContext: ISdkClientContext {
    let eventSignal = JVBroadcastTool<SdkClientContextEvent>()
    
    private let databaseDriver: JVIDatabaseDriver
    
    var clientId: String? {
        didSet {
            databaseDriver.readwrite { [unowned self] context in
                client.m_id = Int64(clientHash)
                client.m_public_id = clientId.jv_orEmpty
            }
            
            eventSignal.broadcast(.clientIdChanged(clientId))
        }
    }
    
    var clientNumber: Int? {
        guard let id = clientId
        else {
            return nil
        }
        
        let params = id.split(separator: ".")
        if params.count == 2, let number = params.first {
            return Int(number)
        }
        else {
            return nil
        }
    }
    
    var clientHash: Int {
        return CRC32.encrypt(client.publicID)
    }
    
    var personalNamespace: String? {
        didSet { eventSignal.broadcast(.personalNamespaceChanged(personalNamespace)) }
    }
    
    var licensing: SdkClientLicensing? {
        didSet { eventSignal.broadcast(.licenseStateUpdated(licensing)) }
    }
    
    var contactInfo = JVSessionContactInfo()

    private var client: JVClient {
        if let object = databaseDriver.client(for: 1, needsDefault: true) {
            return object
        }
        else {
            fatalError()
        }
    }
    
    init(databaseDriver: JVIDatabaseDriver) {
        self.databaseDriver = databaseDriver
    }
    
    internal var remoteStorageToken: String? {
        return personalNamespace
    }
    
    internal func havingAccess(callback: @escaping () -> Void) {
        callback()
    }
    
    internal func isPerson(ofKind kind: String, withID ID: Int) -> Bool {
        guard kind == "client" else { return false }
        return true
    }
    
    internal func supportsRemoteMediaStorage() -> Bool {
        return true
    }
    
    func reset() {
        databaseDriver.readwrite { context in
            client.apply(
                context: context,
                change: JVClientResetChange(ID: client.ID)
            )
        }
        
        clientId = nil
        personalNamespace = nil
        licensing = nil
    }
}
