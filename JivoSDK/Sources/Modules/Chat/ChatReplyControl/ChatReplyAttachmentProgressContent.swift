//
//  ChatReplyAttachmentProgressContent.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 18.11.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

import UIKit

final class ChatReplyAttachmentProgressContent: ChatReplyAttachmentBaseContent {
    let progress: Double
    
    private let waitingIndicator = UIActivityIndicatorView(style: .jv_auto)
    
    init(progress: Double) {
        self.progress = progress
        
        super.init()
        
        waitingIndicator.startAnimating()
        addSubview(waitingIndicator)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.height, height: size.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        waitingIndicator.frame = bounds
    }
}
