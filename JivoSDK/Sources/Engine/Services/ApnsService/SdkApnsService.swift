//
//  SdkApnsService.swift
//  Pods
//
//  Created by Stan Potemkin on 21.08.2022.
//

import Foundation

protocol ISdkApnsService: AnyObject {
    var notificationsDelegate: JVNotificationsDelegate? { get set }
    func setAsking(moment: JVNotificationsPermissionAskingMoment)
    func requestForPermission(at moment: JVNotificationsPermissionAskingMoment)
}

final class SdkApnsService: ISdkApnsService {
    weak var notificationsDelegate: JVNotificationsDelegate?
    
    private let apnsDriver: IApnsDriver
    
    private var askingMoment: JVNotificationsPermissionAskingMoment? = .onConnect
    
    init(apnsDriver: IApnsDriver) {
        self.apnsDriver = apnsDriver
    }
    
    func setAsking(moment: JVNotificationsPermissionAskingMoment) {
        askingMoment = moment
    }
    
    func requestForPermission(at moment: JVNotificationsPermissionAskingMoment) {
        guard moment == askingMoment
        else {
            return
        }
        
        if let delegate = notificationsDelegate {
            delegate.jivoNotifications(accessRequested: .shared, proceedBlock: performDriverRequest)
        }
        else {
            performDriverRequest()
        }
    }
    
    private func performDriverRequest() {
        askingMoment = nil
        
        journal {"APNS: requesting system authorization"}
        apnsDriver.requestForPermission(allowConfiguring: false) { _ in
        }
    }
}
