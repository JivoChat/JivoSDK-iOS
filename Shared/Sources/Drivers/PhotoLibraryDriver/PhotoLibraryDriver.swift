//
//  PhotoLibraryDriver.swift
//  Photornado
//
//  Created by Stan Potemkin on 13/06/2017.
//  Copyright © 2017 bronenos. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

import UIKit
import Photos


protocol IPhotoLibraryDriver: AnyObject {
    var hasAccess: Bool { get }
    
    var requestsObservable: JVBroadcastTool<[UUID]> { get }
    var externalUpdateObservable: JVBroadcastTool<PHChange> { get }

    func update()
    
    func requestAccess(callback: @escaping (Bool) -> Void)
    
    func requestAllAssets(subtype: PHAssetCollectionSubtype,
                          callback: @escaping ([PHAsset]) -> Void)
    
    func requestPhoto(byLocalAssetId localIdentifier: String,
                      sizeType: PhotoSizeType,
                      reasonUUID: UUID,
                      callback: @escaping (PhotoResult) -> Void)
    
    func requestPhoto(asset: PHAsset,
                      sizeType: PhotoSizeType,
                      reasonUUID: UUID,
                      callback: @escaping (PhotoResult) -> Void)
    
    func cancelPhotoRequest(asset: PHAsset,
                            sizeType: PhotoSizeType)
    
    func requestVideoExportURL(asset: PHAsset,
                               reasonUUID: UUID,
                               callback: @escaping (URL?) -> Void)
    
    func hasActiveRequests(forReasonUUID reasonUUID: UUID) -> Bool
    
    func cancelAllRequests()
    
    func deleteAssets(assets: [PHAsset],
                      completion: @escaping (Bool) -> Void)
    
    func obtainPhoto(asset: PHAsset,
                     sizeType: PhotoSizeType) -> UIImage?
}

final class PhotoLibraryDriver: NSObject, IPhotoLibraryDriver, PHPhotoLibraryChangeObserver {
    private struct Request {
        let internalID: PHImageRequestID
        let reasonUUID: UUID
    }

    let requestsObservable = JVBroadcastTool<[UUID]>()
    let externalUpdateObservable = JVBroadcastTool<PHChange>()
    
    private let library = PHPhotoLibrary.shared()
    private lazy var imageManager = PHImageManager.default()
    private lazy var videoCache = PHCachingImageManager()
    private lazy var resourceManager = PHAssetResourceManager.default()
    
    private var photoRequests = [String: Request]()
    private var photoRequestsLock = NSLock()
    private var activeExportSessions = [PHAsset: AVAssetExportSession]()
    
    private var cachedAssets: PHFetchResult<PHAsset>?
    private var detectingUpdates = false
    private var hasUpdates = false
    
    override init() {
        super.init()
        
//        library.register(self)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenshot),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }
    
    deinit {
        library.unregisterChangeObserver(self)
    }
    
    var hasAccess: Bool {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized, .limited: return true
        case .notDetermined, .denied, .restricted: return false
        @unknown default: return true
        }
    }
    
    func update() {
        hasUpdates = true
        notifyAboutUpdatesIfNeeded(change: PHChange())
    }
    
    func requestAccess(callback: @escaping (Bool) -> Void) {
        func _handle(_ status: PHAuthorizationStatus) {
            DispatchQueue.main.async {
                callback(status == .authorized)
            }
        }
        
        let dispatched = dispatchAccess(
            successCallback: { status in _handle(status) },
            failureCallback: { _handle(.denied) }
        )
        
        if !dispatched {
            callback(true)
        }
    }
    
    func requestAllAssets(subtype: PHAssetCollectionSubtype,
                          callback: @escaping ([PHAsset]) -> Void) {
        func _handleSuccess(_ status: PHAuthorizationStatus) {
            DispatchQueue.main.async {
                self.requestAllAssets(subtype: subtype, callback: callback)
            }
        }
        
        func _handleFailure() {
            DispatchQueue.main.async {
                callback([])
            }
        }
        
        let dispatched = dispatchAccess(
            successCallback: _handleSuccess,
            failureCallback: _handleFailure
        )
        
        guard !dispatched else { return }
        
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: subtype,
            options: nil
        )
        
        if let albumCollection = collections.firstObject {
            let assets = PHAsset.fetchAssets(
                in: albumCollection,
                options: nil
            )
            
            cachedAssets = assets
            
            var result = [PHAsset]()
            assets.enumerateObjects({ asset, _, _ in result.append(asset) })
            
            callback(result)
        }
        else {
            callback([])
        }
    }
    
    func requestPhoto(byLocalAssetId localIdentifier: String,
                      sizeType: PhotoSizeType,
                      reasonUUID: UUID,
                      callback: @escaping (PhotoResult) -> Void) {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let results = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: options)
        results.enumerateObjects { (asset, _, _) in
            self.requestPhoto(asset: asset, sizeType: sizeType, reasonUUID: reasonUUID, callback: callback)
        }
    }
    
    func requestPhoto(asset: PHAsset,
                      sizeType: PhotoSizeType,
                      reasonUUID: UUID,
                      callback: @escaping (PhotoResult) -> Void) {
        func _exec() {
            let options = PHImageRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            options.progressHandler = { progress, _, _, _ in callback(.progress(progress)) }
            
            let key = requestKey(asset: asset, sizeType: sizeType)
            let queue = OperationQueue.current ?? OperationQueue.main
            
            let requestID = imageManager.requestImage(
                for: asset,
                targetSize: self.sizeForType(sizeType),
                contentMode: PHImageContentMode.aspectFill,
                options: options,
                resultHandler: { [unowned self] photo, meta in
                    _ = self.unregisterRequest(for: key)
                    
                    if let photo = photo {
                        if let url = meta?["PHImageFileURLKey"] as? URL {
                            let name = url
                                .lastPathComponent
                                .uppercased()
                            
                            queue.addOperation {
                                callback(.image(photo, url, asset.creationDate, name))
                            }
                        }
                        else {
                            let name = asset.localIdentifier
                                .split(separator: "/")
                                .dropFirst()
                                .joined(separator: "/")
                                .uppercased()
                            
                            queue.addOperation {
                                callback(.image(photo, nil, asset.creationDate, name))
                            }
                        }
                    }
                    else if let _ = meta?[PHImageCancelledKey] {
                        queue.addOperation {
                            callback(.failure)
                        }
                    }
                    else if let _ = meta?[PHImageErrorKey] as? Error {
                        queue.addOperation {
                            callback(.failure)
                        }
                    }
                    else if sizeType != .full {
                        queue.addOperation {
                            self.requestPhoto(asset: asset, sizeType: .full, reasonUUID: reasonUUID, callback: callback)
                        }
                    }
                    else {
                        queue.addOperation {
                            callback(.failure)
                        }
                    }
                }
            )
            
            _ = checkRequestKey(key)
            registerRequest(internalID: requestID, reasonUUID: reasonUUID, for: key)
        }
        
        #if ENV_DEBUG
        callback(.progress(0))
        DispatchQueue.main.jv_delayed(seconds: 0.1) { callback(.progress(0.1)) }
        DispatchQueue.main.jv_delayed(seconds: 0.2) { callback(.progress(0.3)) }
        DispatchQueue.main.jv_delayed(seconds: 0.3) { callback(.progress(0.5)) }
        DispatchQueue.main.jv_delayed(seconds: 0.4) { callback(.progress(0.8)) }
        DispatchQueue.main.jv_delayed(seconds: 0.5) { _exec() }
        #else
        callback(.progress(0))
        _exec()
        #endif
    }
    
    func cancelPhotoRequest(asset: PHAsset,
                            sizeType: PhotoSizeType) {
        let key = requestKey(asset: asset, sizeType: sizeType)
        guard let request = unregisterRequest(for: key) else { return }
        imageManager.cancelImageRequest(request.internalID)
    }
    
    func requestVideoExportURL(asset: PHAsset,
                               reasonUUID: UUID,
                               callback: @escaping (URL?) -> Void) {
        let key = requestKey(asset: asset, sizeType: .export)
        
        let requestID = imageManager.requestExportSession(
            forVideo: asset,
            options: nil,
            exportPreset: AVAssetExportPresetPassthrough,
            resultHandler: { [unowned self] session, meta in
                _ = self.unregisterRequest(for: key)
                
                guard let session = session else { return }
                self.activeExportSessions[asset] = session
                
                let fm = FileManager.default
                if let cachedURL = fm.temporaryFileURL(name: "export.MOV") {
                    session.outputFileType = AVFileType.mov
                    session.outputURL = cachedURL
                    
                    session.exportAsynchronously {
                        self.activeExportSessions.removeValue(forKey: asset)
                        
                        DispatchQueue.main.async {
                            switch session.status {
                            case .completed: callback(cachedURL)
                            case .failed, .cancelled: callback(nil)
                            default: break
                            }
                        }
                    }
                }
            }
        )
        
        _ = checkRequestKey(key)
        registerRequest(internalID: requestID, reasonUUID: reasonUUID, for: key)
    }
    
    func hasActiveRequests(forReasonUUID reasonUUID: UUID) -> Bool {
        photoRequestsLock.lock()
        let UUIDs = currentReasonUUIDs
        photoRequestsLock.unlock()

        return UUIDs.contains(reasonUUID)
    }

    func cancelAllRequests() {
        photoRequestsLock.lock()
        photoRequests.values.forEach { imageManager.cancelImageRequest($0.internalID) }
        photoRequestsLock.unlock()

        photoRequests.removeAll()

        requestsObservable.broadcast(currentReasonUUIDs)
    }
    
    func deleteAssets(assets: [PHAsset], completion: @escaping (Bool) -> Void) {
        func _changes() {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }
        
        func _handler(status: Bool, error: Error?) {
            if !status {
                if let _ = error {
//                    print("\(#function): \(error.localizedDescription)")
                }
                else {
                    abort()
                }
            }
            
            DispatchQueue.main.async {
                completion(status)
            }
        }
        
        PHPhotoLibrary.shared().performChanges(_changes, completionHandler: _handler)
    }
    
    func obtainPhoto(asset: PHAsset,
                     sizeType: PhotoSizeType) -> UIImage? {
        let resizeMode: PHImageRequestOptionsResizeMode
        let contentMode: PHImageContentMode
        if sizeType == .model {
            resizeMode = .exact
            contentMode = .aspectFill
        }
        else {
            resizeMode = .fast
            contentMode = .aspectFit
        }
        
        let options = PHImageRequestOptions()
        options.version = .unadjusted
        options.deliveryMode = .highQualityFormat
        options.resizeMode = resizeMode
        options.isSynchronous = true
        
        var result: UIImage?
        
        _ = imageManager.requestImage(
            for: asset,
            targetSize: sizeForType(sizeType),
            contentMode: contentMode,
            options: options,
            resultHandler: { photo, _ in result = photo }
        )
        
        return result
    }

    private var currentReasonUUIDs: [UUID] {
        return photoRequests.values.map { $0.reasonUUID }
    }
    
    private func sizeForType(_ type: PhotoSizeType) -> CGSize {
        switch type {
        case .preview: return CGSize(width: 200, height: 200)
        case .big: return PHImageManagerMaximumSize
        case .full: return PHImageManagerMaximumSize
        case .model: return CGSize(width: 224, height: 224)
        case .export: return CGSize(width: 1500, height: 1500)
        }
    }
    
    private func dispatchAccess(successCallback: @escaping (PHAuthorizationStatus) -> Void,
                                failureCallback: () -> Void) -> Bool {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized, .limited:
            return false
        case .denied:
            failureCallback()
            return true
        case .restricted:
            failureCallback()
            return true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(successCallback)
            return true
        @unknown default:
            return false
        }
    }
    
    private func requestKey(asset: PHAsset, sizeType: PhotoSizeType) -> String {
        return "\(asset.localIdentifier):\(sizeType.rawValue)"
    }
    
    private func registerRequest(internalID: PHImageRequestID, reasonUUID: UUID, for key: String) {
        photoRequestsLock.lock()
        photoRequests[key] = Request(internalID: internalID, reasonUUID: reasonUUID)
        photoRequestsLock.unlock()

        requestsObservable.broadcast(currentReasonUUIDs)
    }
    
    private func checkRequestKey(_ key: String) -> Bool {
        photoRequestsLock.lock()
        let exists = (photoRequests[key] != nil)
        photoRequestsLock.unlock()

        if exists {
//            print("\(#function): request for \(key) is already active")
            return false
        }
        else {
            return true
        }
    }
    
    private func unregisterRequest(for key: String) -> Request? {
        photoRequestsLock.lock()
        let value = photoRequests.removeValue(forKey: key)
        photoRequestsLock.unlock()

        requestsObservable.broadcast(currentReasonUUIDs)

        return value
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard detectingUpdates else { return }
        
        if let cached = cachedAssets, changeInstance.changeDetails(for: cached) == nil {
            return
        }
        
        hasUpdates = true
        notifyAboutUpdatesIfNeeded(change: changeInstance)
    }
    
    private func notifyAboutUpdatesIfNeeded(change: PHChange) {
        DispatchQueue.main.async { [unowned self] in
            let state = UIApplication.shared.applicationState
            guard state != .background else { return }
            
            guard self.hasUpdates else { return }
            self.hasUpdates = false
            
            self.externalUpdateObservable.broadcast(change)
        }
    }

    @objc private func handleApplicationBackground() {
        detectingUpdates = true
    }

    @objc private func handleApplicationForeground() {
        detectingUpdates = false
        notifyAboutUpdatesIfNeeded(change: PHChange())
    }
    
    @objc private func handleScreenshot() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [unowned self] in
            self.update()
        }
    }
}

fileprivate extension FileManager {
    func temporaryFileURL(name: String) -> URL? {
        let cacheURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
        guard let fileURL = cacheURL.appendingPathComponent(name) else { return nil }
        
        if fileExists(atPath: fileURL.path) {
            try? removeItem(at: fileURL)
        }
        
        return fileURL
    }
}
