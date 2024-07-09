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
    var clientId: String? { get }
    var clientNumber: Int? { get }
    var clientHash: Int { get }
    func storeClientId(_ value: String?, async thread: JVIDispatchThread)
    var personalNamespace: String? { get set }
    var licensing: SdkClientLicensing? { get set }
    var contactInfo: JVSessionContactInfo { get set }
    func reset(async thread: JVIDispatchThread)
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
    
    private(set) var clientId: String?
    
    func storeClientId(_ value: String?, async thread: JVIDispatchThread) {
        clientId = value
        eventSignal.broadcast(.clientIdChanged(clientId))

        thread.async { [unowned self] in
            databaseDriver.readwrite { [unowned self] context in
                self.client.m_id = Int64(self.clientHash)
                self.client.m_public_id = self.clientId.jv_orEmpty
                
                if value == nil {
                    self.client.apply(context: context, change: JVClientResetChange(ID: 1))
                }
            }
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
        return CRC32.encrypt(clientId.jv_orEmpty)
    }
    
    var personalNamespace: String? {
        didSet { eventSignal.broadcast(.personalNamespaceChanged(personalNamespace)) }
    }
    
    var licensing: SdkClientLicensing? {
        didSet { eventSignal.broadcast(.licenseStateUpdated(licensing)) }
    }
    
    var contactInfo = JVSessionContactInfo()

    private var client: ClientEntity {
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
    
    func reset(async thread: JVIDispatchThread) {
        storeClientId(nil, async: thread)
        personalNamespace = nil
        licensing = nil
        contactInfo = .init()
    }
}
