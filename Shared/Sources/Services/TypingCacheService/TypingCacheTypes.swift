//
// Created by Stan Potemkin on 30/10/2018.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation


struct TypingCacheRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case context
        case text
    }
    
    let context: TypingContext
    let text: String?
    let attachments: [ChatPhotoPickerObject]
    
    init(context: TypingContext,
         text: String?,
         attachments: [ChatPhotoPickerObject]) {
        self.context = context
        self.text = text
        self.attachments = attachments
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        context = try container.decode(TypingContext.self, forKey: .context)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        attachments = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(context, forKey: .context)
        try container.encode(text, forKey: .text)
    }
}
