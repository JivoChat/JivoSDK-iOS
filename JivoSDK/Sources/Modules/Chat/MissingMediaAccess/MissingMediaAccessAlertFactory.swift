//
//  MissingMediaAccessAlertFactory.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 30.11.2020.
//

import Foundation
import UIKit

enum MissingMediaAccessAlertFactory {
    case photoLibraryUsageAlertController
//    case cameraUsageAlertController(forError: CameraAccessError)
}

extension MissingMediaAccessAlertFactory {
    enum BuildConfiguration {
        case production
    }
}

extension MissingMediaAccessAlertFactory {
    func build(for configuration: BuildConfiguration) -> UIAlertController {
        preconditionFailure()
//        switch configuration {
//        case .production:
//            switch self {
//            case .photoLibraryUsageAlertController:
//                return buildDefaultPhotoLibraryUsageAlertController()
//
//            case let .cameraUsageAlertController(type):
//                switch type {
//                case .denied:
//                    return buildDefaultCameraAccessDeniedController()
//
//                case .restricted:
//                    return buildDefaultCameraAccessRestrictedController()
//                }
//            }
//        }
    }
    
    private func buildDefaultPhotoLibraryUsageAlertController() -> UIAlertController {
        let cameraUsageAlertController = buildCommonMissingAccessAlertController(
            withTitle: loc["JV_SystemAccess_Gallery_NoPermission", "Media.Access.Missing"],
            andMessage: loc["JV_SystemAccess_Gallery_RequestReason", "Media.Access.Suggestion"]
        )
        
        return cameraUsageAlertController
    }
    
    private func buildDefaultCameraAccessDeniedController() -> UIAlertController {
        let cameraUsageAlertController = buildCommonMissingAccessAlertController(
            withTitle: loc["JV_SystemAccess_Camera_NoPermission", "Media.Access.Missing"],
            andMessage: loc["JV_SystemAccess_Camera_RequestReason", "Camera.Access.Suggestion"]
        )
        
        return cameraUsageAlertController
    }
    
    private func buildDefaultCameraAccessRestrictedController() -> UIAlertController {
        let cameraUsageAlertController = buildCommonMissingAccessAlertController(
            withTitle: loc["JV_SystemAccess_Camera_NoPermission", "Camera.Access.Restricted"]
        )
        
        return cameraUsageAlertController
    }
    
    private func buildCommonMissingAccessAlertController(
        withTitle title: String? = nil,
        andMessage message: String? = nil
    ) -> UIAlertController {
        let alertController: UIAlertController = {
            let alertController = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(
                title: loc["JV_Common_Captions_Settings", "Common.Open"],
                style: .default,
                handler: { _ in
                    guard let url = URL.jv_privacy() else { return }
                    UIApplication.shared.open(url)
                }
            ))
            alertController.addAction(UIAlertAction(
                title: loc["JV_Common_Captions_Cancel", "common_cancel"],
                style: .cancel,
                handler: { _ in
                    alertController.dismiss(animated: true)
                }
            ))
            return alertController
        }()
        
        return alertController
    }
}
