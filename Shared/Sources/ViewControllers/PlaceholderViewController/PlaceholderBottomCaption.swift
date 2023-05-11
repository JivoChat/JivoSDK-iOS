//
// Created by Stan Potemkin on 2018-11-30.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation

import UIKit
import TypedTextAttributes

final class PlaceholderBottomCaption: UIView {
    private let label = UILabel()

    let tapHandler: ((UILabel) -> Void)?

    init(caption: String, colorUsage: JVDesignColorUsage, chevron: Bool, tapHandler: ((UILabel) -> Void)?) {
        self.tapHandler = tapHandler

        super.init(frame: .zero)

        let font = obtainHelperFont()
        label.text = caption
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        addSubview(label)

        label.attributedText = caption.attributed(
            TextAttributes()
                .minimumLineHeight(17)
                .foregroundColor(JVDesign.colors.resolve(usage: colorUsage))
                .font(font)
                .alignment(.center)
        )

        if let value = label.attributedText, chevron {
            let complexValue = NSMutableAttributedString(attributedString: value)

            if let _ = tapHandler, let icon = UIImage(named: "ph_arrow") {
                complexValue.append(NSAttributedString(string: " "))
                complexValue.insertIcon(icon, for: font, offset: CGVector(dx: -4, dy: 3))
            }

            label.attributedText = complexValue
        }

        label.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTap))
        )
    }

    required init?(coder aDecoder: NSCoder) {
        self.tapHandler = nil

        super.init(coder: aDecoder)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if label.jv_hasText {
            let height = label.jv_height(forWidth: size.width)
            return CGSize(width: size.width, height: height)
        }
        else {
            return .zero
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }

    @objc private func handleTap() {
        tapHandler?(label)
    }
}

fileprivate func obtainHelperFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(12), scaling: .caption1)
}
