//
//  SignButton.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 05.06.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation


enum SignButtonKind {
    case signIn
    case signUp
}

class SignButton: BaseButton {
    init(kind: SignButtonKind) {
        super.init(
            config: ButtonConfig(
                enabled: true,
                padding: UIEdgeInsets(top: 13, left: 10, bottom: 13, right: 10),
                regularFillColor: JVDesign.colors.resolve(usage: .adaptiveButtonBackground),
                regularTitleColor: JVDesign.colors.resolve(usage: .adaptiveButtonForeground),
                pressedFillColor: nil,
                pressedTitleColor: nil,
                disabledFillColor: nil,
                disabledTitleColor: nil,
                multiline: true,
                fontReducing: true,
                contentAlignment: .center,
                longPressDuration: nil,
                spinner: ButtonSpinner(
                    style: .jv_auto,
                    color: .white,
                    position: .center
                ),
                decoration: ButtonDecoration(
                    cornerRadius: JVDesign.layout.controlBigRadius,
                    border: ButtonDecoration.Border(
                        color: JVDesign.colors.resolve(usage: .adaptiveButtonBorder).jv_withAlpha(0.1),
                        width: 1
                    ),
                    shadow: nil,
                    indicatesTouch: false
                )
            )
        )
        
        imageEdgeInsets.right = 10
        titleEdgeInsets.left = 10
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    final func captionFont() -> UIFont {
        return obtainCaptionFont()
    }
}

fileprivate func obtainCaptionFont() -> UIFont {
    return JVDesign.fonts.resolve(.medium(16), scaling: .callout)
}
