//
//  JMTimelineCompositeMediaBlock.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
#if canImport(JivoFoundation)
import JivoFoundation
#endif
import JMScalableView
import JMTimelineKit

//struct JMTimelineCompositeMediaInfo {
//    let icon: UIImage?
//    let url: URL?
//    let title: String?
//    let subtitle: String?
//
//    init(
//        icon: UIImage?,
//        url: URL?,
//        title: String?,
//        subtitle: String?
//    ) {
//        self.icon = icon
//        self.url = url
//        self.title = title
//        self.subtitle = subtitle
//    }
//}

struct JMTimelineCompositeMediaStyle: JMTimelineStyle {
    let iconTintColor: UIColor
    let titleColor: UIColor
    let subtitleColor: UIColor
    
    init(iconTintColor: UIColor,
                titleColor: UIColor,
                subtitleColor: UIColor) {
        self.iconTintColor = iconTintColor
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
    }
}

final class JMTimelineCompositeMediaBlock: JMTimelineBlock {
    private let iconUnderlay = UIView()
    private let loaderView = UIActivityIndicatorView()
    private let iconView = JMScalableView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    private var url: URL?
    private var style: JMTimelineCompositeMediaStyle!
    
    override init() {
        super.init()
        
        iconUnderlay.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
        addSubview(iconUnderlay)
        
        loaderView.startAnimating()
        addSubview(loaderView)
        
        iconView.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
        iconView.category = UIFont.TextStyle.title1
        iconView.clipsToBounds = true
        iconView.isHidden = true
        addSubview(iconView)
        
        titleLabel.font = obtainTitleFont()
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.numberOfLines = JVDesign.fonts.numberOfLines(standard: 2)
        addSubview(titleLabel)
        
        subtitleLabel.font = obtainSubtitleFont()
        subtitleLabel.numberOfLines = 0
        addSubview(subtitleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(icon: UIImage?, url: URL?, title: String?, subtitle: String?, style: JMTimelineCompositeMediaStyle, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        if let url = url {
            provider.retrieveMeta(forFileWithURL: url) { [weak self] result in
                guard let `self` = self else { return }
                
                self.loaderView.stopAnimating()
                self.loaderView.isHidden = true
                self.iconView.isHidden = false
                
                switch result {
                case let .meta(fileName):
                    self.titleLabel.text = fileName ?? self.titleLabel.text ?? loc["Chat.Media.Unnamed"]
                    
                case let .accessDenied(description):
                    self.configure(withMediaStatus: .accessDenied(description ?? String()))
                    
                case .metaIsNotNeeded:
                    break
                    
                case let .unknownError(description):
                    self.configure(withMediaStatus: .unknownError(description ?? String()))
                    
                @unknown default:
                    break
                }
            }
        }
        
        self.url = url
        self.iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        titleLabel.text = title ?? url?.lastPathComponent
        subtitleLabel.text = subtitle
        
        iconView.tintColor = style.iconTintColor
        titleLabel.textColor = style.titleColor
        subtitleLabel.textColor = style.subtitleColor
    }
    
    func configure(withMediaStatus mediaStatus: JMTimelineMediaStatus) {
        switch mediaStatus {
        case .available:
            break
            
        case let .accessDenied(description):
            self.titleLabel.text = description
            
        case let .unknownError(description):
            self.titleLabel.text = description
            
        @unknown default:
            break
        }
    }
    
//    override func apply(style: JMTimelineStyle) {
//        let style = style.convert(to: JMTimelineCompositeMediaStyle.self)
//        self.style = style
//
//        iconUnderlay.backgroundColor = style.iconBackground
//        iconView.backgroundColor = style.iconBackground
//        iconView.tintColor = style.iconTintColor
//        titleLabel.textColor = style.titleColor
//        subtitleLabel.textColor = style.subtitleColor
//    }
    
    override func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return false
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        iconUnderlay.frame = layout.iconUnderlayFrame
        iconUnderlay.layer.cornerRadius = layout.iconUnderlayCornerRadius
        loaderView.frame = layout.loaderViewFrame
        iconView.frame = layout.iconViewFrame
        iconView.layer.cornerRadius = layout.iconViewCornerRadius
        titleLabel.frame = layout.titleLabelFrame
        subtitleLabel.frame = layout.subtitleLabelFrame
    }
    
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        apply(style: style)
//    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            titleLabel: titleLabel,
            subtitleLabel: subtitleLabel
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let titleLabel: UILabel
    let subtitleLabel: UILabel
    
    private let underlayMargin = CGFloat(7)
    
    var iconUnderlayFrame: CGRect {
        return iconViewFrame.insetBy(dx: -underlayMargin, dy: -underlayMargin)
    }
    
    var iconUnderlayCornerRadius: CGFloat {
        return iconUnderlayFrame.width * 0.5
    }
    
    var loaderViewFrame: CGRect {
        return iconUnderlayFrame
    }
    
    var iconViewFrame: CGRect {
        return CGRect(x: underlayMargin, y: underlayMargin, width: 30, height: 30)
    }
    
    var iconViewCornerRadius: CGFloat {
        return iconViewFrame.width * 0.5
    }
    
    var titleLabelFrame: CGRect {
        let leftX = iconUnderlayFrame.maxX + 10
        let width = bounds.width - leftX
        let height = titleLabel.jv_calculateHeight(forWidth: width)
        return CGRect(x: leftX, y: 0, width: width, height: height)
    }
    
    var subtitleLabelFrame: CGRect {
        let topY = titleLabelFrame.maxY + 5
        let leftX = titleLabelFrame.minX
        let width = bounds.width - leftX
        let height = subtitleLabel.jv_calculateHeight(forWidth: width)
        return CGRect(x: leftX, y: topY, width: width, height: height)
    }
    
    var totalSize: CGSize {
        let labelsRightX = max(titleLabelFrame.maxX, subtitleLabelFrame.maxX)
        let labelsBottomY = subtitleLabel.jv_hasText ? subtitleLabelFrame.maxY : titleLabelFrame.maxY
        
        return CGSize(
            width: min(bounds.width, labelsRightX),
            height: max(iconUnderlayFrame.maxY, labelsBottomY)
        )
    }
}

fileprivate func obtainTitleFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(18), scaling: .headline)
}

fileprivate func obtainSubtitleFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(12), scaling: .caption1)
}
