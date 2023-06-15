//
//  KeyboardListenerTypes.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 02/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

struct KeyboardListenerMeta {
    let height: CGFloat
    let duration: TimeInterval
}

struct KeyboardListenerNotification: Equatable {
    let name: Notification.Name
    let frame: CGRect
}

func ==(lhs: KeyboardListenerNotification, rhs: KeyboardListenerNotification) -> Bool {
    guard lhs.name == rhs.name else { return false }
    guard lhs.frame == rhs.frame else { return false }
    return true
}
