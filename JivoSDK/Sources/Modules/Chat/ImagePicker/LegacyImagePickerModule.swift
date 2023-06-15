//
//  LegacyImagePickerModule.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 15.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import UIKit

class LegacyImagePickerModule: NSObject, ImagePickerModuleProtocol {
    var eventHandler: ((ImagePickerEvent) -> Void)?
    var view: UIViewController? {
        return imagePickerController
    }
    
    private weak var imagePickerController: UIImagePickerController?
    private weak var presentingViewController: UIViewController?
    
    private let availableMediaTypes: [String]
    
    private let sourceType: UIImagePickerController.SourceType
    private let mediaTypes: [String]
    
    init(
        sourceType: UIImagePickerController.SourceType,
        mediaTypes: [String] = [],
        eventHandler: ((ImagePickerEvent) -> Void)? = nil
    ) throws {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            throw InitializationError.sourceIsUnavailable(sourceType.deprecationCleared)
        }
        
        guard
            let availableMediaTypes = UIImagePickerController.availableMediaTypes(for: sourceType),
            !availableMediaTypes.isEmpty
        else {
            throw InitializationError.noAvailableMediaTypes
        }
        
        self.eventHandler = eventHandler
        self.sourceType = sourceType
        self.mediaTypes = mediaTypes
        
        self.availableMediaTypes = availableMediaTypes
        
        super.init()
    }
    
    func present(over presentingViewController: UIViewController, completion: (() -> Void)?) {
        self.presentingViewController = presentingViewController
        
        let imagePickerController = UIImagePickerController()
        self.imagePickerController = imagePickerController
        let availableMediaTypesToSet = mediaTypes.isEmpty
            ? availableMediaTypes
            : mediaTypes.filter(availableMediaTypes.contains(_:))
        imagePickerController.sourceType = sourceType
        imagePickerController.mediaTypes = availableMediaTypesToSet
        imagePickerController.delegate = self
        
        presentingViewController.present(imagePickerController, animated: true, completion: completion)
    }
}

extension LegacyImagePickerModule: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let originalImage = info[UIImagePickerController.InfoKey.originalImage]
        if let image = originalImage as? UIImage {
            eventHandler?(.didPickImage(.success(image)))
        }
        else if let image = originalImage {
            eventHandler?(.didPickImage(.failure(.cannotExtractImage(from: .deprecatedPickerInfoObject(image)))))
        }
        else {
            eventHandler?(.didPickImage(.failure(.cannotExtractImage(from: nil))))
        }
        
        imagePickerController?.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel() {
        imagePickerController?.dismiss(animated: true)
    }
}

extension LegacyImagePickerModule {
    enum InitializationError: Error {
        case sourceIsUnavailable(SourceType?)
        case noAvailableMediaTypes
    }
}

extension LegacyImagePickerModule.InitializationError {
    enum SourceType {
        case photoLibrary
        case camera
    }
}

fileprivate extension UIImagePickerController.SourceType {
    var deprecationCleared: LegacyImagePickerModule.InitializationError.SourceType? {
        switch self {
        case .camera: return .camera
        case .photoLibrary: return .photoLibrary
        case .savedPhotosAlbum: return .photoLibrary
        @unknown default: return nil
        }
    }
}
