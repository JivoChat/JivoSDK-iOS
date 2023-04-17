//
//  GrowingSubmitControlDecl.swift
//  App
//
//  Created by Stan Potemkin on 30.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

enum ChatGrowingSubmitControlOutput<T> {
    case text(value: String, caret: Int?)
    case height(CGFloat)
    case submit(_ text: String)
    case tapAttachment(_ index: Int)
    case discardAttachment(_ index: Int)
    case extra(T)
}
