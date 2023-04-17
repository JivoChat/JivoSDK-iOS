//
//  ICameraDriver.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 18.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import Foundation

enum CameraDriverAccessStatus {
    case authorized
    case denied
    case notDetermined
    case restricted
}

protocol ICameraDriver {
    var accessStatus: CameraDriverAccessStatus { get }
    func requestAccess(handler: @escaping (CameraDriverAccessStatus) -> Void)
}
