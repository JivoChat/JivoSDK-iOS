//
//  ImagePickerModuleProtocol.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 15.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit
import PhotosUI

enum ImagePickerEvent {
    case didPickImage(Result<UIImage, ImagePickerError>)
}

enum ImagePickerError: Error {
    case cannotExtractImage(from: PickedData?)
}

extension ImagePickerError {
    enum PickedData {
        case deprecatedPickerInfoObject(Any)
        case pickerResult(assetId: String?, provider: NSItemProvider)
    }
}

protocol ImagePickerModuleProtocol {
    var eventHandler: ((ImagePickerEvent) -> Void)? { get set }
    var view: UIViewController? { get }
    
    func present(over presentingViewController: UIViewController, completion: (() -> Void)?)
}

extension ImagePickerModuleProtocol {
    func present(over presentingViewController: UIViewController, completion: (() -> Void)? = nil) {
        self.present(over: presentingViewController, completion: completion)
    }
}
