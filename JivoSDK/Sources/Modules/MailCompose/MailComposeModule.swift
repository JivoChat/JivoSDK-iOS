//
//  MailComposeViewControllerDelegate.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 26.08.2021.
//

import Foundation
import MessageUI

enum MailComposeError: Error {
    case cannotSendEmails
}

enum MailComposeEvent {
    case mailSendingCancelled
    case draftSaved
    case mailSuccessfullySent
    case mailSendingFailed
}

class MailComposeModule: NSObject {
    var eventHandler: ((MailComposeEvent) -> Void)?
    
    private weak var mailComposeViewController: MFMailComposeViewController?
    
    private let configuration: MailComposeConfiguration
    
    init?(configuration: MailComposeConfiguration = MailComposeConfiguration(), eventHandler: ((MailComposeEvent) -> Void)? = nil) throws {
        guard MFMailComposeViewController.canSendMail() else {
            throw MailComposeError.cannotSendEmails
        }
        
        self.configuration = configuration
        self.eventHandler = eventHandler
        
        super.init()
    }
    
    deinit {
        mailComposeViewController?.dismiss(animated: true)
    }
    
    func present(over presentingViewController: UIViewController) {
        let mailComposeViewController = buildMailComposeViewController()
        presentingViewController.present(mailComposeViewController, animated: true)
    }
    
    private func buildMailComposeViewController() -> MFMailComposeViewController {
        let mailComposeViewController = MFMailComposeViewController()
        self.mailComposeViewController = mailComposeViewController
        mailComposeViewController.mailComposeDelegate = self
        
        mailComposeViewController.setToRecipients(configuration.recipients)
        configuration.subject.flatMap { mailComposeViewController.setSubject($0) }
        configuration.messageBody.flatMap { mailComposeViewController.setMessageBody($0, isHTML: false) }
        configuration.attachments?.forEach { attachment in
            mailComposeViewController.addAttachmentData(
                attachment.data,
                mimeType: attachment.mimeType,
                fileName: attachment.name
            )
        }
        
        return mailComposeViewController
    }
}

extension MailComposeModule: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        mailComposeViewController?.dismiss(animated: true) { [self] in
            switch result {
            case .cancelled: eventHandler?(.mailSendingCancelled)
            case .saved: eventHandler?(.draftSaved)
            case .sent: eventHandler?(.mailSuccessfullySent)
            case .failed: eventHandler?(.mailSendingFailed)
            @unknown default: break
            }
        }
    }
}
