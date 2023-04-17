//
//  SDKJointTypes.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 16.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import UIKit

enum MediaUploadError: Error {
    case extractionFailed
    case fileSizeExceeded(megabytes: Int)
    case networkClientError
    case cannotHandleUploadResult
    case uploadDeniedByAServer(errorDescription: String? = nil)
    case unsupportedMediaType
    case unknown(errorDescription: String? = nil)
}

struct ChatModuleUIConfig {
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
    let outcomingPalette: ChatTimelinePalette?
    let replyMenuExtraItems: [String]
    let replyMenuCustomHandler: (Int) -> Void
}

enum ChatModuleLicenseState {
    case undefined // when we haven't received the license data yet
    case unlicensed
    case licensed // demo- or pro-license
}
