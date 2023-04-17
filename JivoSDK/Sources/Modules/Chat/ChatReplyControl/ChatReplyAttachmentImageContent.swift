//
//  ChatReplyAttachmentImageContent.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 18.11.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

import UIKit

final class ChatReplyAttachmentImageContent: ChatReplyAttachmentBaseContent {
    private let imageView = UIImageView()
    
    init(image: UIImage?) {
        super.init()
        
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.height, height: size.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
}
