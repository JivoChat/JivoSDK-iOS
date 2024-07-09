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
     Object that handles session events
     */
    @objc(delegate)
    public weak var delegate: JVSessionDelegate? {
        didSet {
            _delegateHookDidSet()
        }
    }
    
    /**
     Specifies preferred server for SDK to connect to Jivo
     */
    @objc(setPreferredServer:)
    public func setPreferredServer(_ server: JVSessionServer) {
        _setPreferredServer(server)
    }
    
    /**
     Starts a logical session for user,
     by either creating a new session or resuming existing one
     
     - Parameter widgetID:
     Your widget_id in Jivo
     - Parameter userToken:
     Either JWT token that you generate to identify a client and keep a history,
     or anonymous mode for temporary chat sessions
     
     > Important: Please take a look here for details about user token:
     > <https://jivochat.github.io/JivoSDK-iOS/documentation/jivosdk/common_user_token>
     
     > Warning: Please avoid calling this method while SDK is displayed onscreen
     */
    public func setup(widgetID: String, clientIdentity: JVClientIdentity) -> JVClient {
        _setup(channelID: widgetID, clientIdentity: clientIdentity)
    }
    
    /**
     Starts a logical session for user,
     by either creating a new session or resuming existing one
     
     - Parameter channelID:
     Your channel ID in Jivo (same as widget_id)
     - Parameter userToken:
     An unique string that you generate to identify a client,
     and it determines whether it is necessary to create a new session with a new dialog,
     or restore an existing one and load the history of the initiated dialog (should be a JWT token)
     
     > Important: Please take a look here for details about user token:
     > <https://jivochat.github.io/JivoSDK-iOS/documentation/jivosdk/common_user_token>

     > Warning: Please avoid calling this method while SDK is displayed onscreen
     */
    @available(*, deprecated, message: "Please use setup(widgetID:userIdentity:) instead")
    @objc(startUpWithChannelID:userToken:)
    public func startUp(channelID: String, userToken: String) {
        _setup(channelID: channelID, clientIdentity: .jwt(userToken))
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
    @available(*, deprecated)
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
    @available(*, deprecated)
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
    
    /*
     For private purposes
     */
    internal let defaultDelegate = DefaultDelegate()
    
    internal override init() {
        self.delegate = defaultDelegate
        
        super.init()
    }
}

extension JVSessionController: SdkEngineAccessing {
    private func _delegateHookDidSet() {
        if let _ = delegate {
            journal(layer: .facade) {"FACADE[session] set the delegate"}
        }
        else {
            journal(layer: .facade) {"FACADE[session] remove the delegate"}
        }
        
        engine.managers.sessionManager.delegate = delegate
        engine.managers.chatManager.sessionDelegate = delegate
    }
    
    private func _setPreferredServer(_ server: JVSessionServer) {
        journal(layer: .facade) {"FACADE[session] set the preferred server @server[\(server.rawValue)]"}
        
        engine.managers.sessionManager.setPreferredServer(server)
    }
    
    internal static let setupFuncKey = "setup"
    private func _setup(channelID channelPath: String, clientIdentity: JVClientIdentity, funcname: String = #function) -> JVClient {
        journal(layer: .facade) {"FACADE[session] setup with channelID[\(channelPath)] clientIdentity[\(clientIdentity)] from func[\(funcname)]"}
        assert(Thread.isMainThread, "Please call on Main Thread")
        
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
        var unreadCounterHandler: ((_ number: Int) -> Void)?
        
        func jivoSession(updateUnreadCounter sdk: Jivo, number: Int) {
            unreadCounterHandler?(number)
        }
    }
}
