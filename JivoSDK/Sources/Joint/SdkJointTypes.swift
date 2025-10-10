//
//  SdkJointTypes.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 16.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit

enum SdkMediaUploadError: Error {
    case extractionFailed
    case fileSizeExceeded(megabytes: Int)
    case networkClientError
    case cannotHandleUploadResult
    case uploadDeniedByAServer(errorDescription: String? = nil)
    case unsupportedMediaType
    case unknown(errorDescription: String? = nil)
}

struct SdkChatModuleVisualConfig {
    let icon: UIImage
    let titleCaption: String
    let titleColor: UIColor
    let subtitleCaption: String
    let subtitleColor: UIColor
    let inputPlaceholder: String
    let inputPrefill: String
    let helloMessage: String
    let offlineMessage: String
    let attachCamera: String
    let attachLibrary: String
    let attachFile: String
    let replyMenuExtraItems: [String]
    let replyMenuCustomHandler: (Int) -> Void
    let replyCursorColor: UIColor
}
