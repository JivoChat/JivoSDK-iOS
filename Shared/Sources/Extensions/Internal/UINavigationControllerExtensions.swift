//
//  UINavigationControllerExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 02/02/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {
    func cut(to: UIViewController, replaceWith: UIViewController?) {
        if let index = viewControllers.firstIndex(of: to) {
            if let replaceWith = replaceWith {
                viewControllers = Array(viewControllers.prefix(upTo: index)) + [replaceWith]
            }
            else {
                viewControllers = Array(viewControllers.prefix(upTo: index + 1))
            }
        }
        else if viewControllers.count > 1 {
            if let replaceWith = replaceWith {
                viewControllers = Array(viewControllers.prefix(0)) + [replaceWith]
            }
            else {
                viewControllers = Array(viewControllers.prefix(0))
            }
        }
    }
}
