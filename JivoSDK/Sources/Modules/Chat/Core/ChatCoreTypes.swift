//
//  ChatCoreTypes.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 16.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import Foundation

enum AlertControllerType {
    case attachmentTypeSelect(AttachmentTypeAlertActions)
    case developerMenu(DeveloperMenuAlertActions)
}

enum AttachmentTypeAlertActions {
    case imageFromLibrary
    case camera
    case document
}

enum DeveloperMenuAlertActions {
    case sendLogs
}
