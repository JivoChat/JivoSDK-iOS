//
//  EmailComposingBridge.swift
//  App
//
//  Created by Stan Potemkin on 19.08.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

protocol IEmailComposingBridge: AnyObject {
    func presentComposer(within container: UIViewController, config: EmailComposingConfig, completion handler: @escaping (EmailComposingOutput) -> Void)
}

struct EmailComposingConfig {
    let to: [String]
    let subject: String?
    let body: String
    let attachments: [Attachment]
}

extension EmailComposingConfig {
    struct Attachment {
        let data: Data
        let mime: String
        let name: String
    }
}

enum EmailComposingOutput {
    case unavailable
    case cancelled
    case drafted
    case sent
    case failed
    case unknown
}

final class EmailComposingBridge: NSObject, IEmailComposingBridge, MFMailComposeViewControllerDelegate {
    private var completionHandler: ((EmailComposingOutput) -> Void)?
    
    func presentComposer(within container: UIViewController, config: EmailComposingConfig, completion handler: @escaping (EmailComposingOutput) -> Void) {
        guard MFMailComposeViewController.canSendMail()
        else {
            handler(.unavailable)
            return
        }
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(config.to.isEmpty ? nil : config.to)
        composer.setMessageBody(config.body, isHTML: false)
        
        for attachment in config.attachments {
            composer.addAttachmentData(attachment.data, mimeType: attachment.mime, fileName: attachment.name)
        }
        
        completionHandler = handler
        container.present(composer, animated: true)
    }
    
    internal func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
        
        switch result {
        case .cancelled:
            completionHandler?(.cancelled)
        case .saved:
            completionHandler?(.drafted)
        case .sent:
            completionHandler?(.sent)
        case .failed:
            completionHandler?(.failed)
        @unknown default:
            completionHandler?(.unknown)
        }
    }
}
