//
//  UIBezierPath+Extension.swift
//  App
//
//  Created by Stan Potemkin on 20.02.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIBezierPath {
    func jv_transformed(_ transform: CGAffineTransform) -> Self {
        apply(transform)
        return self
    }
}
