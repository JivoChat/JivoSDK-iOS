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

enum PickedAttachmentStatus {
    case preparing
    case uploading
}

struct PickedImageMeta {
    let image: UIImage
    let url: URL?
    let assetLocalId: String?
    let date: Date?
    let name: String?
}

struct PickedFileMeta {
    let url: URL
    let name: String
    let size: Int64
    let duration: Int
}

struct PickedAttachmentObject: Equatable {
    let uuid: UUID
    let payload: PickedAttachmentObjectPayload
    
    init(
        uuid: UUID,
        payload: PickedAttachmentObjectPayload
    ) {
        self.uuid = uuid
        self.payload = payload
    }
    
    static func ==(lhs: PickedAttachmentObject, rhs: PickedAttachmentObject) -> Bool {
        guard lhs.uuid == rhs.uuid else { return false }
        return true
    }
}

extension PickedAttachmentObject {
    var isFile: Bool {
        if case .file(_) = self.payload { return true }
        return false
    }
    
    var isImage: Bool {
        if case .image(_) = self.payload { return true }
        return false
    }
    
    var ext: String? {
        switch payload {
        case .image(let meta):
            return meta.url?.pathExtension
        case .file(let meta), .voice(let meta):
            return meta.url.pathExtension
        default:
            return nil
        }
    }
    
    var itemURL: URL? {
        switch payload {
        case .image(let meta):
            return meta.url
        case .file(let meta), .voice(let meta):
            return meta.url
        default:
            return nil
        }
    }
}

enum PickedAttachmentObjectPayload {
    case progress(Double)
    case image(PickedImageMeta)
    case file(PickedFileMeta)
    case voice(PickedFileMeta)
}

enum AttachmentsPickerSource {
    case media
    case file
    case voice
    case video
    case document
}
