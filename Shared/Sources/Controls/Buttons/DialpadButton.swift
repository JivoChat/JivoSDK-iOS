//
//  DialpadButton.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 05/10/2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation

import UIKit

final class DialpadButton: BaseButton {
    init() {
        super.init(
            config: ButtonConfig(
                enabled: true,
                padding: UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15),
                regularFillColor: nil,
                regularTitleColor: JVDesign.colors.resolve(usage: .dialpadButtonForeground),
                pressedFillColor: nil,
                pressedTitleColor: nil,
                disabledFillColor: nil,
                disabledTitleColor: nil,
                multiline: true,
                fontReducing: true,
                contentAlignment: .center,
                longPressDuration: 0.75,
                spinner: nil,
                decoration: ButtonDecoration(
                    cornerRadius: 0,
                    border: nil,
                    shadow: nil,
                    indicatesTouch: true
                )
            )
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    final var caption: NSAttributedString {
        get {
            return NSAttributedString(string: content?.text ?? String())
        }
        set {
            content = ButtonContent.rich(newValue)
        }
    }
}
