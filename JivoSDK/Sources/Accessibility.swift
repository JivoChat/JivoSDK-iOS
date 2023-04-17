//
//  Accessibility.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 03.07.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation

struct Accessibility {
    struct Common {
        static let backButton = "BackButton"
    }
    
    struct Welcome {
        static let loginButton = "LoginButton"
        static let signupButton = "SignupButton"
    }
    
    struct Login {
        static let emailInput = "EmailInput"
        static let passwordInput = "PasswordInput"
        static let loginButton = "LoginButton"
        static let googleButton = "GoogleButton"
        static let errorCaption = "ErrorCaption"
    }

    struct Signup {
        static let emailInput = "EmailInput"
        static let countryPicker = "CountryPicker"
        static let phoneInput = "PhoneInput"
        static let promoInput = "PromoInput"
        static let nextButton = "NextButton"
        static let promoButton = "PromoButton"
        static let acceptButton = "AcceptButton"
        static let loginButton = "LoginButton"
    }
    
    struct Workspace {
        static let menuButton = "MenuButton"
        static let callButton = "CallButton"
        static let statusToggle = "StatusToggle"
        static let inboxTab = "InboxTab"
        static let myboxTab = "MyboxTab"
        static let viboxTab = "ViboxTab"
        static let teamboxTab = "TeamboxTab"
        static let archboxTab = "ArchboxTab"
    }
    
    struct Menu {
        static let preferencesItem = "PreferencesItem"
        static let rateItem = "RateItem"
        static let profileItem = "ProfileItem"
        static let logoutItem = "LogoutItem"
        static let crashItem = "CrashItem"
    }
}
