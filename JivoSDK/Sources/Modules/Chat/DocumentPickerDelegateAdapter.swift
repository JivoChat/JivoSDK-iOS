//
//  DocumentPickerDelegateAdapter.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 19.11.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit

enum DocumentPickerEvent {
    
    case didPickDocuments(at: [URL])
    case didPickDocument(at: URL)
    case wasCancelled(controller: UIDocumentPickerViewController)
}

class DocumentPickerDelegateAdapter: NSObject {
    
    var eventHandler: ((DocumentPickerEvent) -> Void)?
}

extension DocumentPickerDelegateAdapter: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        eventHandler?(.didPickDocuments(at: urls))

//        if let size = urls.first?.fileSize() {
//            engine.services.telemetryService.trackSendFile(tag: currentTelemetryTag, size: size)
//        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        eventHandler?(.didPickDocument(at: url))

//        if let size = url.fileSize() {
//            heartbeat.services.telemetryService.trackSendFile(tag: currentTelemetryTag, size: size)
//        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        eventHandler?(.wasCancelled(controller: controller))
    }
}
