//
// Created by Stan Potemkin on 2019-05-18.
// Copyright (c) 2019 JivoSite. All rights reserved.
//

import Foundation

extension JVSignupCountry {
    var needsPrivacyPolicy: Bool {
        return (code.lowercased() != "ru")
    }
}
