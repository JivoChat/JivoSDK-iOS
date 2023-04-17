//
//  DocumentsBridge.swift
//  App
//
//  Created by Stan Potemkin on 13.08.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

protocol IDocumentsBridge: AnyObject {
    func presentPicker(within viewController: UIViewController, handler: @escaping (DocumentsBridgeEvent) -> Void)
}

enum DocumentsBridgeEvent {
    case documents(urls: [URL])
    case cancel
}

class DocumentsBridge: IDocumentsBridge {
    private var pickerDelegate: PickerDelegate?
    
    func presentPicker(within viewController: UIViewController, handler: @escaping (DocumentsBridgeEvent) -> Void) {
        pickerDelegate = PickerDelegate(parentViewController: viewController, handler: handler)
        
        let picker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeContent)], in: .`import`)
        picker.delegate = pickerDelegate
        viewController.present(picker, animated: true)
    }
}

fileprivate final class PickerDelegate: NSObject, UIDocumentPickerDelegate {
    private weak var parentViewController: UIViewController?
    private var handler: (DocumentsBridgeEvent) -> Void
    
    init(parentViewController: UIViewController, handler: @escaping (DocumentsBridgeEvent) -> Void) {
        self.parentViewController = parentViewController
        self.handler = handler
        
        super.init()
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        fireOnce(event: .documents(urls: urls))
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        fireOnce(event: .documents(urls: [url]))
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        fireOnce(event: .cancel)
    }
    
    private func fireOnce(event: DocumentsBridgeEvent) {
        handler(event)
        handler = { _ in }
//        parentViewController?.dismiss(animated: true)
    }
}
