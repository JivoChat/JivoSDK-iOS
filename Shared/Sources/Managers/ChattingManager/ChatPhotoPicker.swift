//
//  ChatPhotoPicker.swift
//  JivoMobile
//
//  Created by Anton Karpushko on 18.11.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import Photos

enum ChatFileStatus {
    case preparing
    case uploading
}

struct ChatPhotoPickerImageMeta {
    let image: UIImage
    let url: URL?
    let assetLocalId: String?
    let date: Date?
    let name: String?
}

struct ChatPhotoPickerFileMeta {
    let url: URL
    let name: String
    let size: Int64
    let duration: Int
}

struct ChatPhotoPickerObject: Equatable {
    let uuid: UUID
    let payload: ChatPhotoPickerObjectPayload
    
    init(
        uuid: UUID,
        payload: ChatPhotoPickerObjectPayload
    ) {
        self.uuid = uuid
        self.payload = payload
    }
    
    static func ==(lhs: ChatPhotoPickerObject, rhs: ChatPhotoPickerObject) -> Bool {
        guard lhs.uuid == rhs.uuid else { return false }
        return true
    }
}

enum ChatPhotoPickerObjectPayload {
    case progress(Double)
    case image(ChatPhotoPickerImageMeta)
    case file(ChatPhotoPickerFileMeta)
    case voice(ChatPhotoPickerFileMeta)
}

enum AttachmentsPickerSource {
    case media
    case file
    case voice
    case video
    case document
}
