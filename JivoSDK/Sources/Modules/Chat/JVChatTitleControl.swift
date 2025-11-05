//
//  TitleBar.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 12.10.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit
import JMRepicKit


class JVChatTitleControl: UIView {
    
    // MARK: - Public properties
    
    var icon: UIImage? {
        didSet {
            imageView.image = icon
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    var titleLabelText: String = loc["JV_ChatNavigation_HeaderTitle_Default", "chat_title_placeholder"] {
        didSet {
            titleLabel.text = titleLabelText
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    var titleLabelTextColor: UIColor = UIColor.black {
        didSet {
            titleLabel.textColor = titleLabelTextColor
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    var subtitleLabelText: String = loc["JV_ChatNavigation_HeaderSubtitle_Default", "chat_subtitle_placeholder"] {
        didSet {
            subtitleLabel.text = subtitleLabelText
        }
    }
    var subtitleLabelTextColor: UIColor = UIColor.darkGray {
        didSet {
            subtitleLabel.textColor = subtitleLabelTextColor
        }
    }
    
    // MARK: - Private properties
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSubviews()
        applyStyle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Styling
    
    private func applyStyle() {
        imageView.image = icon
        imageView.clipsToBounds = true
        imageView.tintColor = JVDesign.colors.resolve(usage: .secondaryForeground)
        
        titleLabel.text = titleLabelText
        titleLabel.textColor = titleLabelTextColor
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        subtitleLabel.text = subtitleLabelText
        subtitleLabel.textColor = subtitleLabelTextColor
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        let layout = getLayout(size: bounds.size)
        
        imageView.frame = layout.imageViewFrame
        imageView.layer.cornerRadius = imageView.frame.height / 2
        titleLabel.frame = layout.titleLabelFrame
        subtitleLabel.frame = layout.subtitleLabelFrame
    }
    
    private func setupSubviews() {
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    fileprivate func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            safeAreaInsets: safeAreaInsets,
            contentInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            spacing: 14,
            lineSpacing: 0,
            titleLabel: titleLabel,
            subtitleLabel: subtitleLabel,
            displayingImageView: !(imageView.image == nil)
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let safeAreaInsets: UIEdgeInsets
    let contentInsets: UIEdgeInsets
    
    let spacing: CGFloat
    let lineSpacing: CGFloat
    
    let titleLabel: UILabel
    let subtitleLabel: UILabel
    
    let displayingImageView: Bool
    
    var totalSize: CGSize {
        return bounds.size
    }
    
    var imageViewCornerRadius: CGFloat {
        return imageViewSize.height * 0.5
    }
    
    var imageViewSize: CGSize {
        return displayingImageView ? CGSize(width: 36, height: 36) : .zero
    }
    
    var imageViewFrame: CGRect {
        let topY = (bounds.height - imageViewSize.height) * 0.5
        return CGRect(origin: CGPoint(x: contentInsets.left, y: topY), size: imageViewSize)
    }
    
    var titleLabelSize: CGSize {
        let width = totalSize.width - (imageViewFrame.maxX + spacing)
        let height = titleLabel.intrinsicContentSize.height
        return CGSize(width: width, height: height)
    }
    
    var titleLabelFrame: CGRect {
        let topY = (bounds.height - lineSpacing) * 0.5 - titleLabelSize.height
        let leftX = imageViewFrame.maxX + spacing
        return CGRect(origin: CGPoint(x: leftX, y: topY), size: titleLabelSize)
    }
    
    var subtitleLabelSize: CGSize {
        let width = totalSize.width - (imageViewFrame.maxX + spacing)
        let height = subtitleLabel.intrinsicContentSize.height
        return CGSize(width: width, height: height)
    }
    
    var subtitleLabelFrame: CGRect {
        let topY = (bounds.height + lineSpacing) * 0.5
        let leftX = imageViewFrame.maxX + spacing
        return CGRect(origin: CGPoint(x: leftX, y: topY), size: subtitleLabelSize)
    }
}
