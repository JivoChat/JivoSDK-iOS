//
//  NotificationCenterExt.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 21.07.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation

extension NotificationCenter {
    func observeOnMain(forName name: NSNotification.Name?, callback: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return addObserver(forName: name, object: nil, queue: .main, using: callback)
    }
}
