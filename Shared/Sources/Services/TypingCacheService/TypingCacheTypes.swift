//
// Created by Stan Potemkin on 30/10/2018.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation

struct TypingCacheRecord: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case context
        case text
        case mode
    }
    
    let context: TypingContext
    let text: String?
    let attachments: [ChatPhotoPickerObject]
    let mode: InputMode?
    
    var isEmpty: Bool {
        guard text.jv_orEmpty.isEmpty else { return false }
        guard attachments.isEmpty else { return false }
        guard mode == nil else { return false }
        return true
    }
    
    init(
        context: TypingContext,
        text: String?,
        attachments: [ChatPhotoPickerObject],
        mode: InputMode?
    ) {
        self.context = context
        self.text = text
        self.attachments = attachments
        self.mode = mode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        context = try container.decode(TypingContext.self, forKey: .context)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        attachments = []
        mode = try container.decode(InputMode.self, forKey: .mode)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(context, forKey: .context)
        try container.encode(text, forKey: .text)
        try container.encode(mode, forKey: .mode)
    }
}
