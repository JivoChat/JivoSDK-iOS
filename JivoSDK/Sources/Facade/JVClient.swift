//
//  JVClient.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 04.07.2024.
//

import Foundation

public enum JVClientIdentity {
    case jwt(_ userToken: String)
    case anonymous
}

@objc(JVClient)
public final class JVClient: NSObject {
    private weak var controller: JVSessionController?
    
    init(controller: JVSessionController?) {
        self.controller = controller
    }
    
    /**
     Assigns contact info to user,
     to reach him easier in future
     */
    @objc(setContactInfo:)
    public func setContactInfo(_ info: JVClientContactInfo?) {
        controller?._setContactInfo(info)
    }
    
    /**
     Assigns custom data to user,
     if needed for your business
     */
    @objc(setCustomData:)
    public func setCustomData(fields: [JVClientCustomDataField]) {
        controller?._setCustomData(fields: fields)
    }

    /**
     Closes current connection, clears the local database,
     and unsubscribes device from Push Notifications
     */
    @objc(shutDown)
    public func shutDown() {
        controller?._shutDown()
        controller = nil
    }
    
    /**
     Register your handler to observe the unread counter updates
     */
    public func listenToUnreadCounter(handler: ((_ number: Int) -> Void)?) {
        controller?.defaultDelegate.unreadCounterHandler = handler
        controller?.delegate = controller?.defaultDelegate
    }
}
