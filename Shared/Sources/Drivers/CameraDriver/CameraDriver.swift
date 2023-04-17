//
//  CameraDriver.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 18.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import Foundation
import AVFoundation

final class CameraDriver: ICameraDriver {
    var accessStatus: CameraDriverAccessStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }
    
    func requestAccess(handler: @escaping (CameraDriverAccessStatus) -> Void) {
        guard accessStatus == .notDetermined
        else {
            handler(accessStatus)
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] _ in
            DispatchQueue.main.async { [unowned self] in
                handler(accessStatus)
            }
        }
    }
}
