//
//  ApnsDriver.swift
//  App
//
//  Created by Stan Potemkin on 20.08.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
@testable import App

class ApnsDriverMock: IApnsDriver {
    weak var delegate: IApnsDriverDelegate?
    
    init() {
    }
    
    func setupNotifications() {
        fatalError()
    }
    
    var voipToken: String? {
        fatalError()
    }
    
    func setupCalling() {
        fatalError()
    }
    
    func requestForPermission(allowConfiguring: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        fatalError()
    }
    
    func registerActions(categoryId: String, captions: [String]?) {
        fatalError()
    }
    
    func takeRemoteNotification(userInfo: [AnyHashable: Any], originalDate: Date?, actionID: String?, completion: @escaping (Bool) -> Void) {
        fatalError()
    }
    
    func detectTarget(userInfo: [AnyHashable: Any]) -> ApnsNotificationMeta.Target {
        fatalError()
    }
}
