//
//  PopupFlexibleMenuItemCell.swift
//  App
//
//  Created by Yulia Popova on 11.09.2023.
//

import UIKit

struct PopupFlexibleMenuItemOptions: OptionSet {
    let rawValue: Int
    static let withoutSeparator = Self.init(rawValue: 1 << 0)
}

final class PopupFlexibleMenuItemCell: UITableViewCell {
    private let iconView = UIImageView()
    private let leadingLabel = UILabel()
    private let trailingLabel = UILabel()
    private let chevronImageView = UIImageView()
    private let separator = UIView()
    
    init() {
        super.init(style: .default, reuseIdentifier: nil)
        
        backgroundColor = JVDesign.colors.resolve(usage: .groupingBackground)
        selectionStyle = .none
        
        iconView.contentMode = .scaleAspectFit
        
        leadingLabel.font = JVDesign.fonts.resolve(.regular(17), scaling: .body)
        leadingLabel.textColor = JVDesign.colors.resolve(usage: .primaryForeground)
        leadingLabel.numberOfLines = 1
        
        chevronImageView.contentMode = .scaleAspectFit
        
        if #available(iOS 13.0, *) {
            let image = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
            chevronImageView.image = image
            chevronImageView.tintColor = JVDesign.colors.resolve(alias: .steel)
        }
        
        contentView.jv_addSubviews(children: iconView, leadingLabel, trailingLabel, separator, chevronImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(icon: UIImage?, title: String, detail: String?, options: PopupFlexibleMenuItemOptions) {
        iconView.image = icon
        iconView.tintColor = JVDesign.colors.resolve(usage: .secondaryForeground)
        leadingLabel.text = title
        
        if let detailText = detail {
            trailingLabel.textAlignment = .right
            trailingLabel.text = detailText
        }
        else {
            trailingLabel.isHidden = true
            chevronImageView.isHidden = true
        }
        
        trailingLabel.textColor = JVDesign.colors.resolve(usage: .secondaryForeground)
        separator.backgroundColor = options.contains(.withoutSeparator) ? JVDesign.colors.resolve(usage: .clear) : JVDesign.colors.resolve(usage: .secondarySeparator)
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
        
        let layout = getLayout(size: contentView.bounds.size)
        
        iconView.frame = layout.iconFrame
        leadingLabel.frame = layout.titleLabelFrame
        trailingLabel.frame = layout.trailingLabelFrame
        chevronImageView.frame = layout.chevronImageViewFrame
        separator.frame = layout.separatorFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            iconView: iconView,
            leadingLabel: leadingLabel,
            trailingLabel: trailingLabel
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let iconView: UIImageView
    let leadingLabel: UILabel
    let trailingLabel: UILabel
    
    private let horizontalPadding: CGFloat = 20.0
    
    var iconFrame: CGRect {
        if let _ = iconView.image {
            let size = CGSize(width: 28.0, height: 28.0)
            let bottomY = (bounds.height - size.height) / 2
            return CGRect(x: horizontalPadding, y: bottomY, width: size.width, height: size.height)
        }
        else {
            return .zero
        }
    }
    
    var titleLabelFrame: CGRect {
        let leftX: CGFloat
        if let _ = iconView.image {
            leftX = horizontalPadding + iconFrame.maxX
        } else {
            leftX = horizontalPadding
        }
        
        let width = bounds.width - horizontalPadding - leftX
        let height = leadingLabel.jv_calculateHeight(forWidth: width)
        return CGRect(x: leftX, y: (bounds.height - height) / 2, width: width, height: height)
    }
    
    var trailingLabelFrame: CGRect {
        let width = bounds.width
        let height = trailingLabel.jv_calculateHeight(forWidth: width)
        let marginRight = 12.0
        
        return CGRect(
            x: chevronImageViewFrame.minX - width - marginRight,
            y: (bounds.height - height) / 2,
            width: width,
            height: height
        )
    }
    
    var chevronImageViewFrame: CGRect {
        let width = 9.0
        let height = 15.0
        let marginRight = 16.0
        
        return CGRect(
            x: bounds.width - width - marginRight,
            y: (bounds.height - height) / 2,
            width: width,
            height: height
        )
    }
    
    var separatorFrame: CGRect {
        return CGRect(
            x: 20.0,
            y: bounds.height - 1.0,
            width: bounds.width - 20.0,
            height: 1/3
        )
    }
}
