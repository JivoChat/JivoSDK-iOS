//
//  MediaRequestService.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 23/05/2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation

import Photos

protocol IMediaRequestService: AnyObject {
    func hasActiveRequests(recipient: JVSenderData) -> Bool
    func request(asset: PHAsset, recipient: JVSenderData, reasonUUID: UUID, sizeKind: PhotoSizeType, callback: @escaping (MediaResponse) -> Void)
}

final class MediaRequestService: IMediaRequestService {
    private let photoLibraryDriver: IPhotoLibraryDriver

    private var requestedRecipients = [JVSenderData]()

    init(photoLibraryDriver: IPhotoLibraryDriver) {
        self.photoLibraryDriver = photoLibraryDriver
    }

    func hasActiveRequests(recipient: JVSenderData) -> Bool {
        return requestedRecipients.contains(recipient)
    }

    func request(asset: PHAsset, recipient: JVSenderData, reasonUUID: UUID, sizeKind: PhotoSizeType, callback: @escaping (MediaResponse) -> Void) {
        switch asset.mediaType {
        case .image:
            requestedRecipients.append(recipient)
            photoLibraryDriver.requestPhoto(
                asset: asset,
                sizeType: sizeKind,
                reasonUUID: reasonUUID,
                callback: { [unowned self] result in
                    DispatchQueue.main.async {
                        switch result {
                        case .progress(let progress):
                            callback(.progress(progress))
                            
                        case .image(let image, let url, let date, let name):
                            callback(.photo(image, url, date, name))
                            
                            if let index = self.requestedRecipients.firstIndex(of: recipient) {
                                self.requestedRecipients.remove(at: index)
                            }
                            
                        case .failure:
                            break
                        }
                    }
                }
            )

        case .video:
            requestedRecipients.append(recipient)
            photoLibraryDriver.requestVideoExportURL(
                asset: asset,
                reasonUUID: reasonUUID,
                callback: { [unowned self] url in
                    guard let url = url else { return }
                    
                    DispatchQueue.main.async {
                        callback(.video(url))
                        
                        if let index = self.requestedRecipients.firstIndex(of: recipient) {
                            self.requestedRecipients.remove(at: index)
                        }
                    }
                }
            )

        default:
            break
        }
    }
}
