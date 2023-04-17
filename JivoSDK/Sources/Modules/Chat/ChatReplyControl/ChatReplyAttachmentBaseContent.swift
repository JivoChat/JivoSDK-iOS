//
//  ChatReplyAttachmentBaseContent.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 18.11.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

import UIKit

class ChatReplyAttachmentBaseContent: UIView {
    init() {
        super.init(frame: .zero)
        
        backgroundColor = JVDesign.colors.resolve(usage: .contentBackground)
        layer.cornerRadius = 5
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
