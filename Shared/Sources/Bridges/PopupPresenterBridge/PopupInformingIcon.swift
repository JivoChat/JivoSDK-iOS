//
//  PopupInformingIcon.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 15/05/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

final class PopupInformingIcon: UIView {
    private let titleLabel = UILabel()
    private let iconView = UIImageView()
    
    init(title: String, icon: UIImage?, template: Bool, iconMode: UIView.ContentMode) {
        super.init(frame: .zero)
        
        backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
        layer.cornerRadius = JVDesign.layout.alertRadius
        
        titleLabel.text = title
        titleLabel.textColor = JVDesign.colors.resolve(usage: .primaryForeground)
        titleLabel.font = obtainTitleLabelFont()
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)
        
        iconView.image = template ? icon?.withRenderingMode(.alwaysTemplate) : icon
        iconView.tintColor = JVDesign.colors.resolve(usage: .primaryForeground)
        iconView.contentMode = iconMode
        iconView.layer.cornerRadius = 6
        iconView.layer.masksToBounds = true
        addSubview(iconView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let layout = getLayout(size: bounds.size)
        titleLabel.frame = layout.titleLabelFrame
        iconView.frame = layout.iconViewFrame
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: bounds,
            titleLabel: titleLabel,
            iconView: iconView
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let titleLabel: UILabel
    let iconView: UIImageView
    
    private let horizontalMargin = CGFloat(52)
    private let innerMargin = CGFloat(12)

    var titleLabelFrame: CGRect {
        let size = titleLabelSize
        return CGRect(x: horizontalMargin, y: verticalMargin, width: bounds.width - horizontalMargin * 2, height: size.height)
    }
    
    var iconViewFrame: CGRect {
        if let _ = iconView.image {
            let size = iconViewSize
            let leftX = (bounds.width - size.width) * 0.5
            let topY = titleLabel.jv_hasText ? titleLabelFrame.maxY + innerMargin : verticalMargin
            return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
        }
        else {
            return CGRect(x: 0, y: titleLabelFrame.maxY, width: bounds.width, height: 0)
        }
    }
    
    var totalSize: CGSize {
        let width = max(titleLabelSize.width, iconViewSize.width)
        return CGSize(width: width + horizontalMargin * 2, height: iconViewFrame.maxY + verticalMargin)
    }
    
    private var verticalMargin: CGFloat {
        if let _ = iconView.image {
            return 32
        }
        else {
            return 15
        }
    }
    
    private var titleLabelSize: CGSize {
        let parentWidth = bounds.width - horizontalMargin * 2
        return titleLabel.jv_calculateSize(forWidth: parentWidth)
    }
    
    private var iconViewSize: CGSize {
        let limit = CGFloat(200)
        let size = iconView.jv_size(forWidth: limit)
        
        if size.width > limit {
            let coef = size.width / limit
            return CGSize(width: limit, height: size.height / coef)
        }
        else {
            return size
        }
    }
}

fileprivate func obtainTitleLabelFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(18), scaling: .headline)
}
