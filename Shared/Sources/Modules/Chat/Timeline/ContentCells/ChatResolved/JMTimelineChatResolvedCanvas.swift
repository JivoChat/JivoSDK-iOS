//
//  JMTimelineChatResolvedCanvas.swift
//  App
//
//  Created by Julia Popova on 28.06.2024.
//

import Foundation
import UIKit
import DTModelStorage
import JMRepicKit
import JMTimelineKit

final class JMTimelineChatResolvedCanvas: JMTimelineCanvas {
    var closeHandler: (() -> Void)?
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let checkmarkImageView = UIImageView()
    let quitButton = UIButton()
    
    override init() {
        super.init()
        
        accessibilityLabel = "JMTimelineChatResolvedCanvas"
        
        containerView.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
        containerView.jv_addShadow(shadowOpacity: 0.15, shadowRadius: 2.0)
        
        titleLabel.text = loc["Chat.Resolved.Title"]
        titleLabel.font = JVDesign.fonts.resolve(.semibold(16), scaling: .callout)
        titleLabel.numberOfLines = Int.max
        
        descriptionLabel.text = loc["Chat.Resolved.Description"]
        descriptionLabel.font = JVDesign.fonts.resolve(.regular(16), scaling: .callout)
        descriptionLabel.numberOfLines = Int.max
        
        checkmarkImageView.image = UIImage.jv_named("chat_resolved_icon")
        checkmarkImageView.contentMode = .scaleAspectFill
        
        quitButton.setTitle(loc["Chat.Resolved.ActionButton"], for: .normal)
        if #available(iOS 13.0, *) {
            quitButton.backgroundColor = JVDesign.colors.resolve(.native(UIColor.systemGray5))
        }
        quitButton.setTitleColor(JVDesign.colors.resolve(usage: .chatResolvedButton), for: .normal)
        quitButton.titleLabel?.font = JVDesign.fonts.resolve(.semibold(15), scaling: .subheadline)
        quitButton.addTarget(self, action: #selector(handleQuitButtonTap), for: .touchUpInside)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(checkmarkImageView)
        containerView.addSubview(quitButton)
        
        addSubview(containerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure(item: JMTimelineItem) {
        super.configure(item: item)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = Layout(
            size: bounds.size,
            titleLabel: titleLabel,
            descriptionLabel: descriptionLabel
        )
        
        checkmarkImageView.frame = layout.checkmarkImageViewFrame
        titleLabel.frame = layout.titleLabelFrame
        descriptionLabel.frame = layout.descriptionLabelFrame
        quitButton.frame = layout.quitButtonFrame
        
        containerView.frame = layout.containerViewFrame
        
        containerView.layer.cornerRadius = 10.0
        quitButton.layer.cornerRadius = 8.0
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = Layout(size: size, titleLabel: titleLabel, descriptionLabel: descriptionLabel)
        
        return .init(width: size.width, height: layout.containerViewFrame.height + 16.0)
    }
    
    @objc private func handleQuitButtonTap() {
//        closeHandler?()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if quitButton.frame.contains(point) {
            quitButton.becomeFirstResponder()
            closeHandler?()
        }
        
        return super.hitTest(point, with: event)
    }
}

fileprivate struct Layout {
    let size: CGSize
    let titleLabel: UILabel
    let descriptionLabel: UILabel
    
    let containerHorizontalPadding = 10.0
    let imageSize = CGSize(width: 32.0, height: 32.0)
    let textHorizontalPadding = 10.0
    
    var containerWidth: CGFloat {
        return size.width - (16.0 * 2)
    }
    
    var checkmarkImageViewFrame: CGRect {
        return CGRect(origin: .init(x: 16.0, y: 16.0), size: imageSize)
    }
    
    var titleLabelFrame: CGRect {
        let size = titleLabel.sizeThatFits(CGSize(width: containerWidth - checkmarkImageViewFrame.maxX - (2 * textHorizontalPadding), height: .greatestFiniteMagnitude))
        
        return CGRect(
            origin: .init(x: checkmarkImageViewFrame.maxX + textHorizontalPadding, y: 16.0),
            size: .init(
                width: size.width,
                height: size.height
            )
        )
    }
    
    var descriptionLabelFrame: CGRect {
        let size = descriptionLabel.sizeThatFits(CGSize(width: containerWidth - checkmarkImageViewFrame.maxX - (2 * textHorizontalPadding), height: .greatestFiniteMagnitude))
        
        return CGRect(
            origin: .init(
                x: checkmarkImageViewFrame.maxX + textHorizontalPadding,
                y: titleLabelFrame.maxY + 5.0
            ),
            size: .init(
                width: size.width,
                height: size.height
            )
        )
    }
    
    var quitButtonFrame: CGRect {
        return CGRect(
            origin: .init(
                x: descriptionLabelFrame.minX,
                y: descriptionLabelFrame.maxY + 16.0
            ),
            size: .init(
                width: containerWidth - (textHorizontalPadding * 2) - checkmarkImageViewFrame.maxX,
                height: 36.0
            )
        )
    }
    
    var containerViewFrame: CGRect {
        let totalHeight = quitButtonFrame.maxY + 16.0
        return CGRect(
            origin: .init(x: 16.0, y: 0),
            size: .init(width: containerWidth, height: totalHeight)
        )
    }
}
