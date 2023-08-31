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
     Establishes connection between SDK and Jivo,
     by either creating a new session or resuming existing one
     
     - Parameter channelID:
     Your channel ID in Jivo (same as widget_id)
     - Parameter userToken:
     An unique string that you generate to identify a client,
     and it determines whether it is necessary to create a new session with a new dialog,
     or restore an existing one and load the history of the initiated dialog (should be a JWT token)
     
     > Important: Please take a look at "User Token" section of SDK Documentation
     > to know more about how to use JWT here
     
     > Warning: Please avoid calling this method while SDK is displayed onscreen
     */
    @objc(startUpWithChannelID:userToken:)
    public func startUp(channelID: String, userToken: String) {
        _startUp(channelID: channelID, userToken: userToken)
    }
    
    /**
     Assigns contact info to user,
     to reach him easier in future
     */
    @objc(setContactInfo:)
    public func setContactInfo(_ info: JVSessionContactInfo?) {
        _setContactInfo(info)
    }
    
    /**
     Assigns custom data to user,
     if needed for your business
     */
    @objc(setCustomData:)
    public func setCustomData(fields: [JVSessionCustomDataField]) {
        _setCustomData(fields: fields)
    }

    /**
     Closes current connection, clears the local database,
     and unsubscribes device from Push Notifications
     */
    @objc(shutDown)
    public func shutDown() {
        _shutDown()
    }
}

extension JVSessionController: SdkEngineAccessing {
    private func _delegateHookDidSet() {
        if let _ = delegate {
            journal {"FRONT[session] set the delegate"}
        }
        else {
            journal {"FRONT[session] remove the delegate"}
        }
        
        engine.managers.sessionManager.delegate = delegate
        engine.managers.chatManager.sessionDelegate = delegate
    }
    
    private func _setPreferredServer(_ server: JVSessionServer) {
        journal {"FRONT[session] set the preferred server @server[\(server.rawValue)]"}
        
        engine.managers.sessionManager.setPreferredServer(server)
    }
    
    private func _startUp(channelID channelPath: String, userToken: String) {
        guard jv_not(channelPath.hasSuffix("YOUR_CHANNEL_ID"))
        else {
            inform {"Please pass your own channel_id instead of sample value 'YOUR_CHANNEL_ID'"}
            return
        }
        
        journal {"FRONT[session] start up with @channelID[\(channelPath)] @userToken[\(userToken)]"}
        
        engine.managers.sessionManager.startUp(
            channelPath: channelPath,
            clientToken: userToken)
    }
    
    private func _setContactInfo(_ info: JVSessionContactInfo?) {
        if let info = info {
            journal {"FRONT[session] set the contact info @info[\(info)]"}
        }
        else {
            journal {"FRONT[session] remove the contact info"}
        }
        
        engine.managers.clientManager.setContactInfo(
            info: info,
            allowance: .anyField)
    }
    
    private func _setCustomData(fields: [JVSessionCustomDataField]) {
        journal {"FRONT[session] set the custom data @fields[#\(fields.count)]"}

        engine.managers.clientManager.setCustomData(fields: fields)
    }
    
    private func _shutDown() {
        journal {"FRONT[session] shut down"}
        
        engine.managers.notify(event: .turnInactive(.all))
    }
}
