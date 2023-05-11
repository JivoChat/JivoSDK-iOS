//
//  JVCopyrightControl.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 18.12.2020.
//

import UIKit

class JVChatCopyrightControl: UIView {
    
    // MARK: - Private properties
    
    private let titleLabel = UILabel()
    private let logo = UIImageView()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSubviews()
        applyStyle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private methods
    
    private func obtainLocalizedLogo() -> UIImage? {
        return JVDesign.icons.find(logo: .full, lang: JVActiveLocale().jv_langId)
    }
    
    // MARK: - Styling
    
    private func applyStyle() {
        backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground).jv_withAlpha(0.93)
        
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = JVDesign.colors.resolve(usage: .primaryForeground).jv_withAlpha(0.4)
    }
    
    // MARK: Layout
    
    private func setupSubviews() {
        titleLabel.text = loc["jivo_business_messenger"]
        logo.image = obtainLocalizedLogo()
        logo.contentMode = .scaleAspectFit
        
        addSubview(titleLabel)
        addSubview(logo)
    }
    
    override func layoutSubviews() {
        let layout = getLayout(size: bounds.size)
        
        titleLabel.frame = layout.titleLabelFrame
        logo.frame = layout.logoFrame
    }
    
    fileprivate func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: bounds,
            safeAreaInsets: jv_safeInsets,
            contentInsets: UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 10),
            spacing: 6.5,
            titleLabel: titleLabel,
            logo: logo
        )
    }
}

fileprivate struct Layout {
    
    let bounds: CGRect
    let safeAreaInsets: UIEdgeInsets
    
    let contentInsets: UIEdgeInsets
    let spacing: CGFloat
    
    let titleLabel: UILabel
    let logo: UIImageView
    
    var safeAreaFrame: CGRect {
        return bounds.jv_reduceBy(insets: safeAreaInsets)
    }
    
    var totalSize: CGSize {
        return bounds.size
    }
    
    var logoSize: CGSize {
        let imageAspectRatio: CGFloat = (logo.image?.size.width ?? 0) / (logo.image?.size.height ?? 1)
        let height = totalSize.height - contentInsets.top - contentInsets.bottom
        return CGSize(width: height * imageAspectRatio, height: height)
    }
    
    var logoFrame: CGRect {
        return CGRect(origin: CGPoint(x: totalSize.width - contentInsets.right - logoSize.width, y: totalSize.height / 2 - logoSize.height / 2), size: logoSize)
    }
    
    var titleLabelSize: CGSize {
        return CGSize(width: titleLabel.intrinsicContentSize.width, height: totalSize.height - contentInsets.top - contentInsets.bottom)
    }
    
    var titleLabelFrame: CGRect {
        return CGRect(origin: CGPoint(x: logoFrame.minX - spacing - titleLabelSize.width, y: totalSize.height / 2 - titleLabelSize.height / 2), size: titleLabelSize)
    }
}
