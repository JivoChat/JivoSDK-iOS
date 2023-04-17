//
//  MailComposeConfiguration.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 26.08.2021.
//

import Foundation

struct MailComposeConfiguration {
    let recipients: [String]?
    let subject: String?
    let messageBody: String?
    let attachments: [Attachment]?
    
    init(
        recipients: [String]? = nil,
        subject: String? = nil,
        messageBody: String? = nil,
        attachments: [Attachment]? = nil
    ) {
        self.recipients = recipients
        self.subject = subject
        self.messageBody = messageBody
        self.attachments = attachments
    }
}

extension MailComposeConfiguration {
    struct Attachment {
        let data: Data
        let mimeType: String
        let name: String
    }
}
