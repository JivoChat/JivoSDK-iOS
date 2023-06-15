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
    
    init(
        image: UIImage,
        url: URL?,
        assetLocalId: String? = nil,
        date: Date?,
        name: String?
    ) {
        self.image = image
        self.url = url
        self.assetLocalId = assetLocalId
        self.date = date
        self.name = name
    }
}

struct ChatPhotoPickerFileMeta {
    let url: URL
    let name: String
    let size: Int64
    let duration: Int
    
    init(
        url: URL,
        name: String,
        size: Int64,
        duration: Int
    ) {
        self.url = url
        self.name = name
        self.size = size
        self.duration = duration
    }
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

enum ChatPhotoPickerType {
    case media
    case file
    case voice
}
