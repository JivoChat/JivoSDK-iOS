//
//  PhotoPickingBridge.swift
//  App
//
//  Created by Stan Potemkin on 17.08.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import PhotosUI


enum PhotoPickingBridgeSource {
    case library
    case camera
}

enum PhotoPickingBridgeError: Error {
    case extractionFailed
}

typealias PhotoPickingCompletion = (Result<[PhotoPickingResult], PhotoPickingBridgeError>) -> Void
struct PhotoPickingResult {
    let media: PhotoPickingMedia
    let name: String?
}

enum PhotoPickingMedia {
    case image(UIImage)
    case video(URL)
}

protocol IPhotoPickingBridge: AnyObject {
    func presentPicker(within container: UIViewController, source: PhotoPickingBridgeSource, completion: @escaping PhotoPickingCompletion)
}

final class PhotoPickingBridge: NSObject, IPhotoPickingBridge, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let attachmentsNumberLimit: Int
    private let popupPresenterBridge: IPopupPresenterBridge
    private let photoLibraryDriver: IPhotoLibraryDriver
    private let cameraDriver: ICameraDriver
    
    private let loadingQueue: DispatchQueue
    private lazy var loadingSemaphore = DispatchSemaphore(value: 1)
    private var completion: PhotoPickingCompletion?

    init(namespace: String, attachmentsNumberLimit: Int, popupPresenterBridge: IPopupPresenterBridge, photoLibraryDriver: IPhotoLibraryDriver, cameraDriver: ICameraDriver) {
        self.attachmentsNumberLimit = attachmentsNumberLimit
        self.popupPresenterBridge = popupPresenterBridge
        self.photoLibraryDriver = photoLibraryDriver
        self.cameraDriver = cameraDriver
        
        loadingQueue = DispatchQueue(label: "\(namespace).photo-picker.queue", qos: .userInteractive)
        
        super.init()
    }
    
    func presentPicker(within container: UIViewController, source: PhotoPickingBridgeSource, completion: @escaping PhotoPickingCompletion) {
        self.completion = completion
        
        switch source {
        case .library:
            requestFromLibrary(within: container, completion: completion)
        case .camera:
            requestFromCamera(within: container, completion: completion)
        }
    }
    
    private func requestFromLibrary(within container: UIViewController, completion: @escaping PhotoPickingCompletion) {
        if #available(iOS 14, *) {
            photoLibraryDriver.requestAccess { [unowned self] hasAccess in
                switch hasAccess {
                case true:
                    var config = PHPickerConfiguration(photoLibrary: .shared())
                    config.filter = .images
                    config.preferredAssetRepresentationMode = .current
                    config.selectionLimit = attachmentsNumberLimit
                    
                    let picker = PHPickerViewController(configuration: config)
                    picker.delegate = self
                    container.present(picker, animated: true)
                    
                case false:
                    popupPresenterBridge.displayAlert(
                        within: .specific(container),
                        title: loc["JV_SystemAccess_Gallery_NoPermission", "Media.Access.Missing"],
                        message: loc["JV_SystemAccess_Gallery_RequestReason", "Media.Access.Suggestion"],
                        items: [
                            .action(loc["JV_Common_Captions_Settings", "Common.Open"], .noicon, .regular { _ in
                                guard let url = URL.jv_privacy() else { return }
                                UIApplication.shared.open(url)
                            }),
                            .dismiss(.close)
                        ])
                }
            }
        }
        else {
            guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
            else {
                return popupPresenterBridge.displayAlert(
                    within: .specific(container),
                    title: nil,
                    message: loc["JV_SystemAccess_Gallery_NoSource", "PhotoLibrary.Access.Unavailable"],
                    items: [
                        .dismiss(.close)
                    ])
            }
            
            guard let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary),
                  !(availableTypes.isEmpty)
            else {
                return popupPresenterBridge.displayAlert(
                    within: .specific(container),
                    title: nil,
                    message: loc["JV_SystemAccess_Gallery_NoContent", "PhotoLibrary.Access.NoAvailableImages"],
                    items: [
                        .dismiss(.close)
                    ])
            }
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            container.present(picker, animated: true)
        }
    }
    
    private func requestFromCamera(within container: UIViewController, completion: @escaping PhotoPickingCompletion) {
        cameraDriver.requestAccess { [unowned self] status in
            switch status {
            case .authorized:
                guard UIImagePickerController.isSourceTypeAvailable(.camera)
                else {
                    return popupPresenterBridge.displayAlert(
                        within: .specific(container),
                        title: nil,
                        message: loc["JV_SystemAccess_Camera_NoSource", "Camera.Access.Unavailable"],
                        items: [
                            .dismiss(.close)
                        ])
                }
                
                guard let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera),
                      !(availableTypes.isEmpty)
                else {
                    return popupPresenterBridge.displayAlert(
                        within: .specific(container),
                        title: nil,
                        message: loc["JV_SystemAccess_Gallery_NoContent", "PhotoLibrary.Access.NoAvailableImages"],
                        items: [
                            .dismiss(.close)
                        ])
                }
                
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                container.present(picker, animated: true)
                
            case .denied:
                popupPresenterBridge.displayAlert(
                    within: .specific(container),
                    title: loc["JV_SystemAccess_Camera_NoPermission", "Media.Access.Missing"],
                    message: loc["JV_SystemAccess_Camera_RequestReason", "Camera.Access.Suggestion"],
                    items: [
                        .dismiss(.close)
                    ])
                
            case .restricted:
                popupPresenterBridge.displayAlert(
                    within: .specific(container),
                    title: loc["JV_SystemAccess_Camera_NoPermission", "Camera.Access.Restricted"],
                    message: nil,
                    items: [
                        .dismiss(.close)
                    ])
                
            case .notDetermined:
                break
            }
        }
    }
    
    @available(iOS 14.0, *)
    internal func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        results.forEach { result in
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                loadingQueue.async { [unowned self] in
                    loadingSemaphore.wait()
                    
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [unowned self] object, error in
                        loadingSemaphore.signal()
                        
                        DispatchQueue.main.async { [unowned self] in
                            if let image = object as? UIImage {
                                let info = PhotoPickingResult(
                                    media: .image(image),
                                    name: result.itemProvider.suggestedName
                                )
                                
                                completion?(.success([info]))
                            }
                            else if let _ = object {
                                completion?(.failure(.extractionFailed))
                            }
                            else {
                                completion?(.failure(.extractionFailed))
                            }
                        }
                    }
                }
            }
            else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                loadingQueue.async { [unowned self] in
                    loadingSemaphore.wait()
                    
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [unowned self] url, error in
                        loadingSemaphore.signal()
                        
                        DispatchQueue.main.async { [unowned self] in
                            if let url = url {
                                let info = PhotoPickingResult(
                                    media: .video(url),
                                    name: result.itemProvider.suggestedName
                                )
                                
                                completion?(.success([info]))
                            }
                            else {
                                completion?(.failure(.extractionFailed))
                            }
                        }
                    }
                }
            }
        }
        
        picker.dismiss(animated: true)
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let originalImage = info[UIImagePickerController.InfoKey.originalImage]
        let originalVideoUrl = info[UIImagePickerController.InfoKey.mediaURL]

        if let image = originalImage as? UIImage {
            let info = PhotoPickingResult(
                media: .image(image),
                name: nil
            )
            
            completion?(.success([info]))
        }
        else if let _ = originalImage {
            completion?(.failure(.extractionFailed))
        }
        else if let url = originalVideoUrl as? URL {
            let info = PhotoPickingResult(
                media: .video(url),
                name: nil
            )
            
            completion?(.success([info]))
        }
        else if let _ = originalVideoUrl {
            completion?(.failure(.extractionFailed))
        }
        else {
            completion?(.failure(.extractionFailed))
        }
        
        picker.dismiss(animated: true)
    }
    
    internal func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
