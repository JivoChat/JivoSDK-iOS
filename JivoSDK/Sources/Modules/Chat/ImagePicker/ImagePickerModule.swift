//
//  ImagePickerModule.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 15.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import UIKit
import PhotosUI

@available(iOS 14, *)
class ImagePickerModule: NSObject, ImagePickerModuleProtocol {
    var eventHandler: ((ImagePickerEvent) -> Void)?
    var view: UIViewController? {
        return pickerViewController
    }
    
    private weak var pickerViewController: PHPickerViewController?
    private weak var presentingViewController: UIViewController?
    
    private let imageLoadingQueue: DispatchQueue
    private let semaphore = DispatchSemaphore(value: 1)
    
    private let configuration: PHPickerConfiguration
    
    init(
        configuration: PHPickerConfiguration,
        imageLoadingQueue: DispatchQueue,
        eventHandler: ((ImagePickerEvent) -> Void)? = nil
    ) {
        self.configuration = configuration
        self.imageLoadingQueue = imageLoadingQueue
        self.eventHandler = eventHandler
        
        super.init()
    }
    
    func present(over presentingViewController: UIViewController, completion: (() -> Void)?) {
        self.presentingViewController = presentingViewController
        
        let pickerViewController = PHPickerViewController(configuration: configuration)
        self.pickerViewController = pickerViewController
        pickerViewController.delegate = self
        
        presentingViewController.present(pickerViewController, animated: true, completion: completion)
    }
    
    private func handlePickerResults(_ results: [PHPickerResult]) {
        results.forEach { result in
            let itemProvider = result.itemProvider
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                loadImageWith(assetId: result.assetIdentifier, provider: itemProvider)
            } else {
                eventHandler?(.didPickImage(.failure(.cannotExtractImage(
                    from: .pickerResult(
                        assetId: result.assetIdentifier,
                        provider: itemProvider
                    )
                ))))
            }
        }
    }
    
    private func loadImageWith(assetId: String?, provider: NSItemProvider) {
        imageLoadingQueue.async { [weak self] in
            self?.semaphore.wait()
            
            provider.loadObject(ofClass: UIImage.self) { object, error in
                self?.semaphore.signal()
                
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        self?.eventHandler?(.didPickImage(.success(image)))
                    }
                    else if let _ = object {
                        self?.eventHandler?(.didPickImage(.failure(.cannotExtractImage(
                            from: .pickerResult(
                                assetId: assetId,
                                provider: provider
                            )
                        ))))
                    }
                    else {
                        self?.eventHandler?(.didPickImage(.failure(.cannotExtractImage(from: nil))))
                    }
                }
            }
        }
    }
}

@available(iOS 14, *)
extension ImagePickerModule: PHPickerViewControllerDelegate {
    func picker(_ pickerViewController: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        handlePickerResults(results)
        
        pickerViewController.dismiss(animated: true)
    }
}
