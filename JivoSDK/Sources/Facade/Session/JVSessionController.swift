//
//  SessionFacade.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 03.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

/**
 ``Jivo``.``Jivo/session`` namespace for managing user session
 */
@objc(JVSessionController)
public final class JVSessionController: NSObject {
    /**
     Specifies preferred server for SDK to connect to Jivo
     */
    public func setPreferredServer(_ server: JVSessionServer) {
        _setPreferredServer(server)
    }
    
    @objc(__setPreferredServer:)
    public func __setPreferredServer(_ name: String) {
        if let server = JVSessionServer(rawValue: name) {
            _setPreferredServer(server)
        }
        else {
            _setPreferredServer(.auto)
        }
    }
    
    /**
     Starts a logical session for user,
     by either creating a new session or resuming existing one
     
     - Parameter widgetID:
     Your widget_id in Jivo
     - Parameter clientIdentity:
     Either JWT token that you generate to identify a client and keep a history,
     or anonymous mode for temporary chat sessions
     
     > Important: Please take a look here for details about user token:
     > <https://jivochat.github.io/JivoSDK-iOS/documentation/jivosdk/common_user_token>
     
     > Warning: Please avoid calling this method while SDK is displayed onscreen
     */
    public func setup(widgetID: String, clientIdentity: JVClientIdentity) -> JVClient {
        _setup(channelID: widgetID, clientIdentity: clientIdentity)
    }

    @discardableResult
    @objc(__setupWidgetID:userToken:)
    public func __setup(widgetID: String, userToken: String?) -> JVClient {
        if let userToken {
            _setup(channelID: widgetID, clientIdentity: .jwt(userToken))
        }
        else {
            _setup(channelID: widgetID, clientIdentity: .anonymous)
        }
    }
    
    /**
     Assigns contact info to user,
     to reach him easier in future
     
     Deprecated, please use another form:
     ```swift
     let client = Jivo.session.setup(...)
     client.setContactInfo(...)
     ```
     */
    @objc(setContactInfo:)
    public func setContactInfo(_ info: JVClientContactInfo?) {
        _setContactInfo(info)
    }
    
    /**
     Assigns custom data to user,
     if needed for your business
     
     Deprecated, please use another form:
     ```swift
     let client = Jivo.session.setup(...)
     client.setCustomData(...)
     */
    @objc(setCustomData:)
    public func setCustomData(fields: [JVClientCustomDataField]) {
        _setCustomData(fields: fields)
    }

    /**
     Closes current connection, clears the local database,
     and unsubscribes device from Push Notifications
     
     You also may use another form:
     ```swift
     let client = Jivo.session.setup(...)
     client.shutDown()
     */
    @objc(shutDown)
    public func shutDown() {
        _shutDown()
    }
    
    /**
     Handler will be called when unread counter changes
     
     - Parameter callback:
     Block that will be called on future counter updates
     */
    @objc(listenToUnreadCounter:)
    public func listenToUnreadCounter(callback: @escaping (Int) -> Void) {
        _listenToUnreadCounter(callback: callback)
    }
    
    /*
     For private purposes
     */
    internal let defaultDelegate = DefaultDelegate()
    
    internal override init() {
        super.init()
        engine.managers.sessionManager.delegate = defaultDelegate
        engine.managers.chatManager.sessionDelegate = defaultDelegate
    }
}

extension JVSessionController: SdkEngineAccessing {
    private func _setPreferredServer(_ server: JVSessionServer) {
        journal(layer: .facade) {"FACADE[session] set the preferred server @server[\(server.rawValue)]"}
        
        engine.managers.sessionManager.setPreferredServer(server)
    }
    
    internal static let setupFuncKey = "setup"
    private func _setup(channelID channelPath: String, clientIdentity: JVClientIdentity, funcname: String = #function) -> JVClient {
        journal(layer: .facade) {"FACADE[session] setup with channelID[\(channelPath)] clientIdentity[\(clientIdentity)]"}
        assert(Thread.isMainThread, "Please call on Main Thread")
        
        let localizableKeys = SdkChatNotificationLocalizableKey.allCases.map(\.rawValue)
        for key in localizableKeys {
            let hasTranslation = (NSLocalizedString(key, comment: .jv_empty) != key)
            if !hasTranslation {
                let localizableFmt = localizableKeys.joined(separator: .jv_enumerator)
                assertionFailure("Please make sure you have specified [\(localizableFmt)] keys within your Localizable, as described here <https://jivochat.github.io/JivoSDK-iOS/documentation/jivosdk/common_project_config>")
            }
        }
        
        Thread.current.threadDictionary[Self.setupFuncKey] = funcname
        DispatchQueue.main.async {
            Thread.current.threadDictionary[Self.setupFuncKey] = nil
        }
        
        switch clientIdentity {
        case .anonymous:
            engine.managers.sessionManager.setup(channelPath: channelPath, userToken: .jv_empty)
        case .jwt(.jv_empty):
            engine.managers.sessionManager.setup(channelPath: channelPath, userToken: .jv_empty)
        case .jwt(let jwt):
            engine.managers.sessionManager.setup(channelPath: channelPath, userToken: jwt)
        }
        
        return JVClient(controller: Jivo.session)
    }
    
    private func _listenToUnreadCounter(callback: @escaping (Int) -> Void) {
        journal(layer: .facade) {"FACADE[session] listenToUnreadCounter"}
        
        defaultDelegate.unreadCounterHandler = callback
    }
    
    internal func _setContactInfo(_ info: JVSessionContactInfo?) {
        if let info = info {
            journal(layer: .facade) {"FACADE[session] set the contact info @info[\(info)]"}
        }
        else {
            journal(layer: .facade) {"FACADE[session] remove the contact info"}
        }
        
        engine.managers.clientManager.setContactInfo(
            info: info,
            allowance: .anyField)
    }
    
    internal func _setCustomData(fields: [JVClientCustomDataField]) {
        journal(layer: .facade) {"FACADE[session] set the custom data @fields[#\(fields.count)]"}

        engine.managers.clientManager.setCustomData(fields: fields)
    }
    
    internal func _shutDown() {
        journal(layer: .facade) {"FACADE[session] shut down"}
        
        engine.threads.workerThread.async { [unowned self] in
            engine.managers.notify(event: .turnInactive(.all))
        }
    }
}

extension JVSessionController {
    internal final class DefaultDelegate: NSObject, JVSessionDelegate {
        var unreadCounterHandler: ((Int) -> Void)?
        
        func jivoSession(updateUnreadCounter sdk: Jivo, number: Int) {
            unreadCounterHandler?(number)
        }
    }
}
