//
// Created by Stan Potemkin on 2019-03-07.
// Copyright (c) 2019 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
import UIKit

final class WrapperBarItem: UIBarButtonItem {
    var tapHandler: (() -> Void)?

    let button = UIButton()

    init(customIcon: UIImage?) {
        super.init()

        button.setImage(customIcon, for: .normal)
        button.tintColor = JVDesign.colors.resolve(usage: .navigatorTint)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        
        customView = ContainerView(
            contentView: button,
            margins: UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 3)
        )
    }

    required init?(coder aDecoder: NSCoder) {
        abort()
    }

    @objc private func handleTap() {
        tapHandler?()
    }
}
