//
//  PopupFlexibleMenuTitleCell.swift
//  App
//
//  Created by Yulia Popova on 11.09.2023.
//

import UIKit

final class PopupFlexibleMenuTitleCell: UITableViewCell {
    private let titleLabel = UILabel()
    
    init() {
        super.init(style: .default, reuseIdentifier: nil)
        
        backgroundColor = JVDesign.colors.resolve(usage: .groupingBackground)
        selectionStyle = .none
        
        titleLabel.font = JVDesign.fonts.resolve(.regular(16), scaling: .caption1)
        titleLabel.textColor = JVDesign.colors.resolve(usage: .secondaryForeground)
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(title: String) {
        titleLabel.text = title
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds

        let layout = getLayout(size: contentView.bounds.size)
        titleLabel.frame = layout.titleLabelFrame
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            titleLabel: titleLabel
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let titleLabel: UILabel
    
    fileprivate let insets = UIEdgeInsets(top: 12, left: 17, bottom: 2, right: 17)

    var titleLabelFrame: CGRect {
        let width = bounds.width - insets.horizontal
        let height = titleLabel.jv_calculateHeight(forWidth: width)
        return CGRect(x: insets.left, y: insets.top, width: width, height: height)
    }
    
    var totalSize: CGSize {
        let bottomY = titleLabelFrame.maxY
        return CGSize(width: bounds.width, height: bottomY + insets.bottom)
    }
}
