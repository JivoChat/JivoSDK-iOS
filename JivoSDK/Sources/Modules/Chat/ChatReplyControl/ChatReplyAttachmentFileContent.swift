//
//  ChatReplyAttachmentFileContent.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 18.11.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

import UIKit

final class ChatReplyAttachmentFileContent: ChatReplyAttachmentBaseContent {
    private let titleLabel = UILabel()
    
    private let margin = CGFloat(10)
    
    init(url: URL) {
        super.init()
        
        titleLabel.text = url.lastPathComponent
        titleLabel.textColor = JVDesign.colors.resolve(usage: .primaryForeground)
        titleLabel.font = obtainTitleFont()
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingHead
        addSubview(titleLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let size = titleLabel.sizeThatFits(size)
        return CGSize(width: min(150, size.width + margin * 2), height: size.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = bounds.insetBy(dx: margin, dy: 0)
    }
}

fileprivate func obtainTitleFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(13...15), scaling: .footnote)
}
