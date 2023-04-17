//
//  UIGestureRecognizerExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 14/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIGestureRecognizer {
    func firedInside(view: UIView) -> Bool {
        let point = location(in: view)
        return view.bounds.contains(point)
    }
}
