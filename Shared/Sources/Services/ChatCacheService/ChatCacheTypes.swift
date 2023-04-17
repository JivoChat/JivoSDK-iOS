//
//  ChatCacheTypes.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 22/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

struct ChatCacheEarliestMeta {
    let chatID: Int
    let message: JVMessage
}
