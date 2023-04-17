//
//  SberButton.swift
//  SberButton
//
//  Created by Stan Potemkin on 26.07.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation

import UIKit

final class SberButton: SignButton {
    override init(kind: SignButtonKind) {
        super.init(kind: kind)
        
        switch kind {
        case .signIn:
            content = ButtonContent.media(
                UIImage(named: "sign_sber"),
                loc["Auth.Sber.SignIn"],
                captionFont())
        case .signUp:
            content = ButtonContent.media(
                UIImage(named: "sign_sber"),
                loc["Auth.Sber.SignUp"],
                captionFont())
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
