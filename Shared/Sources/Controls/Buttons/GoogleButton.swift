//
//  GoogleButton.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 14.11.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation

import UIKit

final class GoogleButton: SignButton {
    override init(kind: SignButtonKind) {
        super.init(kind: kind)
        
        switch kind {
        case .signIn:
            content = ButtonContent.media(
                UIImage(named: "sign_google"),
                loc["Auth.Google.SignIn"],
                captionFont())
        case .signUp:
            content = ButtonContent.media(
                UIImage(named: "sign_google"),
                loc["Auth.Google.SignUp"],
                captionFont())
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
