//
// Created by Stan Potemkin on 30/10/2018.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation

protocol TypingCacheInput {
    var text: String? { get }
    var attachments: [PickedAttachmentObject] { get }
    var mode: InputMode? { get }
    var aiSummarizeNumber: Int { get }
    var whatsappTarget: String? { get }
    var actualityTimestamp: Date { get }
}

struct TypingCacheRecord: TypingCacheInput, Codable, Equatable {
    let context: TypingContext
    
    var text: String? {
        didSet {
            actualityTimestamp = Date()
        }
    }
    
    var attachments: [PickedAttachmentObject] {
        didSet {
            actualityTimestamp = Date()
        }
    }
    
    var mode: InputMode? {
        didSet {
            actualityTimestamp = Date()
        }
    }
    
    var aiSummarizeNumber: Int {
        didSet {
            actualityTimestamp = Date()
        }
    }
    
    var whatsappTarget: String? {
        didSet {
            actualityTimestamp = Date()
        }
    }
    
    var actualityTimestamp: Date {
        didSet {
            actualityTimestamp = Date()
        }
    }
    
    
    init(
        context: TypingContext
    ) {
        self.context = context
        self.text = nil
        self.attachments = .jv_empty
        self.mode = .regular
        self.aiSummarizeNumber = 0
        self.whatsappTarget = nil
        self.actualityTimestamp = Date()
    }
    
    init(
        context: TypingContext,
        text: String?,
        attachments: [PickedAttachmentObject],
        mode: InputMode?,
        aiSummarizeNumber: Int,
        whatsappTarget: String?,
        actualityTimestamp: Date
    ) {
        self.context = context
        self.text = text
        self.attachments = attachments
        self.mode = mode
        self.aiSummarizeNumber = aiSummarizeNumber
        self.whatsappTarget = whatsappTarget
        self.actualityTimestamp = actualityTimestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        context = try container.decode(TypingContext.self, forKey: .context)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        attachments = []
        mode = try container.decodeIfPresent(InputMode.self, forKey: .mode)
        aiSummarizeNumber = try container.decode(Int.self, forKey: .aiSummarizeNumber)
        whatsappTarget = try container.decodeIfPresent(String.self, forKey: .whatsappTarget)
        actualityTimestamp = try container.decode(Date.self, forKey: .actualityTimestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(context, forKey: .context)
        try container.encode(text, forKey: .text)
        try container.encode(mode, forKey: .mode)
        try container.encode(aiSummarizeNumber, forKey: .aiSummarizeNumber)
        try container.encode(whatsappTarget, forKey: .whatsappTarget)
        try container.encode(actualityTimestamp, forKey: .actualityTimestamp)
    }
    
    var isEmpty: Bool {
        guard text.jv_orEmpty.isEmpty else { return false }
        guard attachments.isEmpty else { return false }
        guard mode == nil else { return false }
        return true
    }
}

fileprivate extension TypingCacheRecord {
    enum CodingKeys: String, CodingKey {
        case context
        case text
        case mode
        case lastChatID
        case aiSummarizeNumber
        case whatsappTarget
        case actualityTimestamp
    }
} 
