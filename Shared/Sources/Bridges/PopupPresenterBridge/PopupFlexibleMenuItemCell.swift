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
    private let titleLabel = UILabel()
    private let separator = UIView()
    
    init() {
        super.init(style: .default, reuseIdentifier: nil)
        
        backgroundColor = JVDesign.colors.resolve(usage: .groupingBackground)
        selectionStyle = .none
        
        iconView.contentMode = .scaleAspectFit
        contentView.addSubview(iconView)
        
        titleLabel.font = JVDesign.fonts.resolve(.regular(17), scaling: .body)
        titleLabel.textColor = JVDesign.colors.resolve(usage: .primaryForeground)
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        
        contentView.addSubview(separator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(icon: UIImage?, title: String, options: PopupFlexibleMenuItemOptions) {
        iconView.image = icon
        iconView.tintColor = JVDesign.colors.resolve(usage: .secondaryForeground)
        titleLabel.text = title
        separator.backgroundColor = options.contains(.withoutSeparator) ? JVDesign.colors.resolve(usage: .clear) : JVDesign.colors.resolve(usage: .secondarySeparator)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds

        let layout = getLayout(size: contentView.bounds.size)
        iconView.frame = layout.iconFrame
        titleLabel.frame = layout.titleLabelFrame
        separator.frame = layout.separatorFrame
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            iconView: iconView,
            titleLabel: titleLabel
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let iconView: UIImageView
    let titleLabel: UILabel
    
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
        let height = titleLabel.jv_calculateHeight(forWidth: width)
        return CGRect(x: leftX, y: (totalSize.height - height) / 2, width: width, height: height)
    }
    
    var totalSize: CGSize {
        return CGSize(width: bounds.width, height: 44.0)
    }
    
    var separatorFrame: CGRect {
        return CGRect(
            x: 20.0,
            y: totalSize.height - 1.0,
            width: bounds.width - 20.0,
            height: 1.0
        )
    }
}
