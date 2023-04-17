//
//  AppleButton.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 05.06.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation

import UIKit

final class AppleButton: SignButton {
    override init(kind: SignButtonKind) {
        super.init(kind: kind)
        
        switch kind {
        case .signIn:
            content = ButtonContent.media(
                UIImage(named: "sign_apple"),
                loc["Auth.Apple.SignIn"],
                captionFont())
        case .signUp:
            content = ButtonContent.media(
                UIImage(named: "sign_apple"),
                loc["Auth.Apple.SignUp"],
                captionFont())
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
