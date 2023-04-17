//
//  JivoImpl.swift
//  SDK
//
//  Created by Stan Potemkin on 21.03.2023.
//

import Foundation

@objc(Jivo)
public final class Jivo: NSObject {
    static let shared = Jivo()
    let session = JVSessionController()
    let display = JVDisplayController()
    let notifications = JVNotificationsController()
    let debugging = JVDebuggingController()
}

func inform(messageProvider: () -> String) {
    print("Jivo: \(messageProvider())")
}
