//
//  SdkApnsService.swift
//  Pods
//
//  Created by Stan Potemkin on 21.08.2022.
//

import Foundation

protocol ISdkApnsService: AnyObject {
    var notificationsCallbacks: JVNotificationsCallbacks? { get set }
    func setAsking(moment: JVNotificationsPermissionAskingMoment)
    func requestForPermission(at moment: JVNotificationsPermissionAskingMoment)
}

final class SdkApnsService: ISdkApnsService {
    weak var notificationsCallbacks: JVNotificationsCallbacks?
    
    private let apnsDriver: IApnsDriver
    
    private var askingMoment: JVNotificationsPermissionAskingMoment? = .sessionSetup
    
    init(apnsDriver: IApnsDriver) {
        self.apnsDriver = apnsDriver
    }
    
    func setAsking(moment: JVNotificationsPermissionAskingMoment) {
        askingMoment = moment
    }
    
    func requestForPermission(at moment: JVNotificationsPermissionAskingMoment) {
        guard moment == askingMoment else {
            return
        }
        
        if let handler = notificationsCallbacks?.accessIntroHandler {
            handler(performDriverRequest)
        }
        else {
            performDriverRequest()
        }
    }
    
    private func performDriverRequest() {
        askingMoment = nil
        
        journal(layer: .notifications) {"APNS: requesting system authorization"}
        apnsDriver.requestForPermission(allowConfiguring: false) { _ in
        }
    }
}
