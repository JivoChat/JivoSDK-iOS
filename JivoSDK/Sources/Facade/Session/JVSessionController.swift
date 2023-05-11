//
//  SessionFacade.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 03.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

/**
 Responsible for everything related to the communication session,
 such as connection and client data
 */
@objc(JVSessionController)
public final class JVSessionController: NSObject {
    /**
     Delegate for handling events related to connection and client session
     
     > Note: At the moment, the ``JivoSessionDelegate`` protocol does not contain any declarations within itself.
     > Let us know what properties or callback methods you would like to see in it
     */
    @objc(delegate)
    public weak var delegate: JVSessionDelegate? {
        didSet {
            _delegateHookDidSet()
        }
    }
    
    /**
     Sets the preferred server for SDK connection to Jivo backend
     */
    @objc(setPreferredServer:)
    public func setPreferredServer(_ server: JVSessionServer) {
        _setPreferredServer(server)
    }
    
    /**
     Establishes a connection between the SDK and our servers,
     either creating a new session or resuming an existing one
     
     > Warning: Please avoid calling this method while JivoSDK is displayed onscreen
     
     - Parameter channelID:
     Your channel ID in Jivo (same as widget_id)
     - Parameter userToken:
     An unique string that you generate to identify a client
     and determines whether it is necessary to create a new session with a new dialog,
     or restore an existing one and load the history of the initiated dialog
     */
    @objc(startUpWithChannelID:userToken:)
    public func startUp(channelID: String, userToken: String) {
        _startUp(channelID: channelID, userToken: userToken)
    }
    
    /**
     Specifies the contact info for the client, to communicate him easier in future
     */
    @objc(setContactInfo:)
    public func setContactInfo(_ info: JVSessionContactInfo?) {
        _setContactInfo(info)
    }
    
    /**
     Specifies additional info about a client needed for your business,
     such as his order id
     */
    @objc(setCustomData:)
    public func setCustomData(fields: [JVSessionCustomDataField]) {
        _setCustomData(fields: fields)
    }

    /**
     Closes the current connection, cleans up the local database,
     and sends a request to unsubscribe the device from Push Notifications to the client session
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
