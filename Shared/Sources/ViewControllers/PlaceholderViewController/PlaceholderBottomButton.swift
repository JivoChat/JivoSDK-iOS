//
// Created by Stan Potemkin on 2018-12-01.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation

import UIKit
import TypedTextAttributes

final class PlaceholderBottomButton: UIView {
    private let button = TriggerButton(style: .primary, weight: .bold)

    init(title: String, tapHandler: ((UIButton) -> Void)?) {
        super.init(frame: .zero)

        button.caption = title
        addSubview(button)
        
        button.shortTapHandler = { [ref = button] in
            tapHandler?(ref)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return button.jv_size(forWidth: size.width)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = bounds
    }
}
