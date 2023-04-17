//
//  AlertableIconExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 15/05/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension PopupInformingIcon {
    class func timeBreak() -> PopupInformingIcon? {
        if let icon = UIImage(named: "coffee_break") {
            return PopupInformingIcon(
                title: loc["Alert.TimeBreak.Title"],
                icon: icon,
                template: true,
                iconMode: .center)
        }
        else {
            return nil
        }
    }
    
    class func copied() -> PopupInformingIcon {
        return PopupInformingIcon(
            title: loc["Common.Copied"],
            icon: nil,
            template: true,
            iconMode: .center)
    }
}
