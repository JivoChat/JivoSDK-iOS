//
//  CGAffineTransform+Extension.swift
//  App
//
//  Created by Stan Potemkin on 20.02.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

extension CGAffineTransform {
    static let rotateClockwise = Self.init(rotationAngle: 90.0 * .pi / 180.0)
    static let upsideDown = Self.init(scaleX: 1, y: -1)
}
