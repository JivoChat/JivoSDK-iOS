//
// Created by Stan Potemkin on 2019-05-18.
// Copyright (c) 2019 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

extension JVSignupCountry {
    var needsPrivacyPolicy: Bool {
        return (code.lowercased() != "ru")
    }
}
