//
//  ChatReplyAttachmentControl.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 18.11.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import JivoFoundation

import UIKit

final class ChatReplyAttachmentControl: UIView {
    var contentTapHandler: (() -> Void)?
    var dismissTapHandler: (() -> Void)?
    
    private let dismissButton = ChatReplyAttachmentDismissButton()
    private var content = UIView()
    
    init(payload: ChatPhotoPickerObjectPayload) {
        self.payload = payload
        
        super.init(frame: .zero)
        
        content = generateContent(for: payload)
        addSubview(content)
        
        dismissButton.backgroundColor = JVDesign.colors.resolve(usage: .destructiveBrightButtonBackground)
        dismissButton.imageView?.tintColor = JVDesign.colors.resolve(usage: .destructiveButtonForeground)
        dismissButton.setImage(UIImage(named: "close", in: Bundle(for: SdkChatReplyControl.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        dismissButton.addTarget(self, action: #selector(handleDismissTap), for: .touchUpInside)
        addSubview(dismissButton)
        
        content.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleContentTap))
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var payload: ChatPhotoPickerObjectPayload {
        didSet {
            content.removeFromSuperview()
            content = generateContent(for: payload)
            addSubview(content)
            
            bringSubviewToFront(dismissButton)
            
            content.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(handleContentTap))
            )
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -5, dy: -5).contains(point)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        content.frame = layout.contentFrame
        dismissButton.frame = layout.dismissButtonFrame
        dismissButton.layer.cornerRadius = layout.dismissButtonCornerRadius
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            content: content
        )
    }
    
    private func generateContent(for payload: ChatPhotoPickerObjectPayload) -> UIView {
        switch payload {
        case .progress(let progress):
            return ChatReplyAttachmentProgressContent(progress: progress)
        case .image(let meta):
            return ChatReplyAttachmentImageContent(image: meta.image)
        case .file(let meta):
            return ChatReplyAttachmentFileContent(url: meta.url)
        case .voice(let meta):
            return ChatReplyAttachmentFileContent(url: meta.url)
        }
    }
    
    @objc private func handleContentTap() {
        contentTapHandler?()
    }
    
    @objc private func handleDismissTap() {
        dismissTapHandler?()
    }
}

fileprivate class ChatReplyAttachmentDismissButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -5, dy: -5).contains(point)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let content: UIView
    
    let dismissButtonOverlap = CGSize(width: 3, height: 3)
    
    var contentFrame: CGRect {
        let size = content.sizeThatFits(bounds.size)
        let topY = dismissButtonOverlap.height
        return CGRect(x: 0, y: topY, width: size.width, height: bounds.height - topY)
    }
    
    var dismissButtonFrame: CGRect {
        let size = CGSize(width: 15, height: 15)
        let topY = -dismissButtonOverlap.height
        let leftX = bounds.width - size.width + dismissButtonOverlap.width
        return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
    }
    
    var dismissButtonCornerRadius: CGFloat {
        return dismissButtonFrame.height * 0.5
    }
    
    var totalSize: CGSize {
        let size = content.sizeThatFits(bounds.size)
        let overlap = dismissButtonOverlap
        return CGSize(width: size.width + overlap.width, height: size.height + overlap.height)
    }
}

